const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 8080;

const server = http.createServer((req, res) => {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', '*');

    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    const parsedUrl = url.parse(req.url, true);
    const targetUrl = parsedUrl.query.url;

    if (!targetUrl) {
        res.writeHead(400);
        res.end('Missing "url" query parameter');
        return;
    }

    console.log(`Proxying request to: ${targetUrl}`);

    https.get(targetUrl, (proxyRes) => {
        // Forward status and headers (except existing CORS headers)
        const headers = { ...proxyRes.headers };
        delete headers['access-control-allow-origin'];
        
        res.writeHead(proxyRes.statusCode, headers);
        proxyRes.pipe(res);
    }).on('error', (err) => {
        console.error(err);
        res.writeHead(500);
        res.end('Error fetching target URL');
    });
});

server.listen(PORT, () => {
    console.log(`Local CORS proxy running at http://localhost:${PORT}/?url=`);
});
