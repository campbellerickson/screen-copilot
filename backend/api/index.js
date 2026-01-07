"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
// Vercel serverless function entry point
const server_1 = __importDefault(require("../src/server"));
// Export the Express app directly
// Vercel will compile TypeScript automatically
exports.default = server_1.default;
//# sourceMappingURL=index.js.map