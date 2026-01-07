"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = handler;
function handler(req, res) {
    return res.status(200).json({
        message: 'Vercel serverless function is working!',
        timestamp: new Date().toISOString(),
        path: req.url,
        method: req.method
    });
}
//# sourceMappingURL=test.js.map