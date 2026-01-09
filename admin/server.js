const express = require('express');
const Redis = require('ioredis');
const app = express();

const redis = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: 6379
});

app.use(express.static('public'));
app.use(express.json());

// Helper to normalized scope key
const getKey = (scope) => `maintenance:${scope || 'GLOBAL'}`;

// Get Status for a specific scope
app.get('/api/maintenance', async (req, res) => {
    const scope = req.query.scope || 'GLOBAL';
    try {
        const data = await redis.get(getKey(scope));
        const status = data ? JSON.parse(data) : { active: false };
        res.json({ scope, ...status });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Set Status for a specific scope
app.post('/api/maintenance', async (req, res) => {
    const { active, message, scope } = req.body;
    const targetScope = scope || 'GLOBAL';

    const payload = JSON.stringify({
        active,
        message: message || "Maintenance in progress"
    });

    try {
        await redis.set(getKey(targetScope), payload);
        res.json({ success: true, scope: targetScope, active });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

const PORT = 3000;
app.listen(PORT, () => {
    console.log(`Admin server running on port ${PORT}`);
});
