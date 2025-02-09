const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    const { access_token } = req.query;

    if (access_token) {
        res.send('Email confirmation successful! You can now log in.');
        // Optionally, log the token for debugging
        console.log('Access token:', access_token);
    } else {
        res.send('Hello World! No token provided.');
    }
});

app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
});
