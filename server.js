require("dotenv").config();
const express = require("express");
const axios = require("axios");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

// Load environment variables
const PORT = process.env.PORT || 5000;
const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE;
const SECRET_API_KEY = process.env.SECRET_API_KEY;

// Debugging: Log environment variables
console.log("🔹 SUPABASE_URL:", SUPABASE_URL);
console.log("🔹 SERVICE_ROLE_KEY exists:", !!SERVICE_ROLE_KEY);
console.log("🔹 SECRET_API_KEY exists:", !!SECRET_API_KEY);

// Middleware to verify API key
const verifyAPIKey = (req, res, next) => {
    const apiKey = req.headers["x-api-key"];
    if (!apiKey || apiKey !== SECRET_API_KEY) {
        return res.status(403).json({ error: "Unauthorized" });
    }
    next();
};

// ✅ Email Verification Route 
app.get("/auth-user", async (req, res) => {
    const { access_token } = req.query; // Extract access_token from the query parameters
    
    if (!access_token) {
        return res.status(400).json({ error: "No access token found." });
    }

    try {
        // Use the access_token to get user info from Supabase
        const { data: user, error } = await axios.get(
            `${SUPABASE_URL}/auth/v1/user`, // Supabase endpoint to get user info using the access token
            {
                headers: {
                    apikey: SERVICE_ROLE_KEY, // Admin API key
                    Authorization: `Bearer ${access_token}`, // Authorization with the access token
                },
            }
        );

        if (error || !user) {
            return res.status(401).json({ error: "Invalid access token" });
        }

        console.log("✅ User authenticated:", user.email);

        // Redirect back to the frontend with the access token in the URL
        res.redirect(`your-app://login-success?token=${access_token}`);
    } catch (error) {
        console.error("❌ Authentication failed:", error);
        res.status(500).json({ error: "Failed to authenticate user" });
    }
});



// ✅ User Deletion Route
const tables = {
    "swap_requests": ["requester_id", "receiver_id"],
    "chats": ["senderID", "receiverID"],
    "Reviews": ["UserID"],
    "item": ["userID"],
    "users": ["UserID"],
};

app.delete("/delete-user", verifyAPIKey, async (req, res) => {
    const { userID } = req.body;
    if (!userID) return res.status(400).json({ error: "User ID is required" });

    try {
        console.log(`🗑️ Deleting user data for: ${userID}...`);

        // Delete associated records
        for (const [table, columns] of Object.entries(tables)) {
            for (const column of columns) {
                await axios.delete(
                    `${SUPABASE_URL}/rest/v1/${table}?${column}=eq.${userID}`,
                    {
                        headers: {
                            apikey: SERVICE_ROLE_KEY,
                            Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
                            "Content-Type": "application/json",
                        },
                    }
                );
            }
        }

        // Delete user from Supabase Auth
        await axios.delete(`${SUPABASE_URL}/auth/v1/admin/users/${userID}`, {
            headers: {
                apikey: SERVICE_ROLE_KEY,
                Authorization: `Bearer ${SERVICE_ROLE_KEY}`,
                "Content-Type": "application/json",
            },
        });

        res.status(200).json({ message: "User deleted successfully" });
    } catch (error) {
        res.status(500).json({ error: "Failed to delete user" });
    }
});

// ✅ Start the server
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});