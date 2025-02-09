require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// Load environment variables
const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE;
const SECRET_API_KEY = process.env.SECRET_API_KEY;

// Debugging: Log environment variables to ensure they load
console.log("🔹 SUPABASE_URL:", SUPABASE_URL);
console.log("🔹 SERVICE_ROLE_KEY exists:", !!SERVICE_ROLE_KEY);
console.log("🔹 SECRET_API_KEY exists:", !!SECRET_API_KEY);

// Middleware to verify API key
const verifyAPIKey = (req, res, next) => {
    console.log("🔹 Full Headers:", req.headers);

    const apiKey = req.headers["x-api-key"];
    console.log("🔹 Received API Key:", apiKey);

    if (!apiKey) {
        console.log("❌ No API Key received");
        return res.status(403).json({ error: "Missing API Key" });
    }

    if (apiKey !== SECRET_API_KEY) {
        console.log("❌ Invalid API Key received:", apiKey);
        return res.status(403).json({ error: "Unauthorized" });
    }

    console.log("✅ API Key Verified!");
    next();
};

// Mapping of tables and their respective user-related columns
const tables = {
    "swap_requests": ["requester_id", "receiver_id"],   // User can be requester or receiver
    "chats": ["senderID", "receiverID"],  // User can be sender or receiver
    "Reviews": ["UserID"],   // User ID reference
    "item": ["userID"],   // User ID reference
    "users": ["UserID"],   // User's own ID in users table
};

// DELETE /delete-user
app.delete("/delete-user", verifyAPIKey, async (req, res) => {
    const { userID } = req.body;
    if (!userID) {
        console.log("❌ Missing UserID in request body");
        return res.status(400).json({ error: "User ID is required" });
    }

    try {
        console.log(`🗑️ Deleting user data for: ${userID}...`);

        // Step 1: Delete associated records in other tables before deleting from `users`
        for (const [table, columns] of Object.entries(tables)) {
            for (const column of columns) {
                try {
                    const deleteResponse = await axios.delete(
                        `${SUPABASE_URL}/rest/v1/${table}?${column}=eq.${userID}`,
                        {
                            headers: {
                                apikey: SERVICE_ROLE_KEY,
                                Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
                                "Content-Type": "application/json",
                            },
                        }
                    );
                    console.log(`✅ Deleted from ${table} (where ${column}=${userID}):`, deleteResponse.status);
                } catch (error) {
                    console.error(`❌ Error deleting from ${table} (column: ${column}):`, error.response?.data || error.message);
                }
            }
        }

        // Step 2: Delete user from auth.users
        try {
            const authResponse = await axios.delete(
                `${SUPABASE_URL}/auth/v1/admin/users/${userID}`,
                {
                    headers: {
                        apikey: SERVICE_ROLE_KEY,
                        Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
                        "Content-Type": "application/json",
                    },
                }
            );
            console.log(`✅ User ${userID} deleted from Supabase Auth:`, authResponse.status);
        } catch (error) {
            console.error("❌ Error deleting from auth.users:", error.response?.data || error.message);
        }

        res.status(200).json({ message: "User deleted successfully" });

    } catch (error) {
        console.error("❌ Unexpected Error:", error.response?.data || error.message);
        res.status(500).json({ error: "Failed to delete user" });
    }
});

// Start server
const PORT = 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
