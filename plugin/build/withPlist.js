"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const config_plugins_1 = require("@expo/config-plugins");
const withPlist = (expoConfig) => (0, config_plugins_1.withInfoPlist)(expoConfig, (plistConfig) => {
    const scheme = typeof expoConfig.scheme === 'string' ? expoConfig.scheme : expoConfig.ios?.bundleIdentifier;
    if (scheme)
        plistConfig.modResults.CFBundleURLTypes = [{ CFBundleURLSchemes: [scheme] }];
    return plistConfig;
});
exports.default = withPlist;
