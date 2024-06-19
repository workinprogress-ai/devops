#!/usr/bin/env zx

import { readdir, stat, copyFile, readFile, writeFile, mkdir, access } from 'fs/promises';
import path from 'path';
import process from 'process';

async function isFile(filePath) {
    try {
        const stats = await stat(filePath);
        return stats.isFile();
    } catch {
        return false;
    }
}

async function loadConfig(configPath) {
    const configContent = await readFile(configPath, 'utf-8');
    return JSON.parse(configContent);
}

function matchPattern(item, patterns) {
    return patterns.some(pattern => new RegExp(pattern.replace('.', '\\.').replace('*', '.*')).test(item));
}

async function doTextReplacements(filePath, replacements) {
    let content = await readFile(filePath, 'utf-8');
    for (const [from, to] of Object.entries(replacements)) {
        content = content.replace(new RegExp(from, 'g'), to);
    }
    await writeFile(filePath, content, 'utf-8');
}

function doPathReplacements(filePath, replacements) {
    let newPath = filePath;
    for (const [from, to] of Object.entries(replacements)) {
        newPath = newPath.replace(new RegExp(from, 'g'), to);
    }
    return newPath;
}

async function copyFiles(srcDir, tgtDir, config) {
    const items = await readdir(srcDir, { withFileTypes: true });
    let folderCreated = false;

    for (const item of items) {
        const srcItemPath = path.join(srcDir, item.name);
        const tgtItemPath = doPathReplacements(path.join(tgtDir, item.name), config.REPLACE_NAMES);

        if (item.isDirectory()) {
            if (config.EXCLUDE_FOLDERS.some(pattern => srcItemPath.includes(pattern))) continue;
            if (config.INCLUDE_FOLDERS.length && !config.INCLUDE_FOLDERS.some(pattern => srcItemPath.includes(pattern))) continue;

            await copyFiles(srcItemPath, tgtItemPath, config);
        } else {
            if (config.EXCLUDE_FILES.length && matchPattern(item.name, config.EXCLUDE_FILES)) continue;

            let shouldCopy = matchPattern(item.name, config.INCLUDE_FILES);
            if (!shouldCopy && matchPattern(item.name, config.INCLUDE_IF_NOT_EXISTS_FILES) && !(await isFile(tgtItemPath))) {
                shouldCopy = true;
            }

            if (shouldCopy) {
                if (!folderCreated) {
                    await mkdir(tgtDir, { recursive: true });
                    folderCreated = true;
                }

                await copyFile(srcItemPath, tgtItemPath);
                await doTextReplacements(tgtItemPath, config.REPLACE_CONTENT);
            }
        }
    }
}

async function processTargetDirectory(tgtDir, sourceRoot) {
    const configPath = path.join(tgtDir, 'sync_profile.json');
    if (await isFile(configPath)) {
        console.log(`Found config file: ${configPath}`);
        const config = await loadConfig(configPath);
        const srcDir = path.join(sourceRoot, config.SOURCE_PATH);

        console.log(`Processing directory: ${tgtDir}`);
        console.log(`Source directory: ${srcDir}`);

        await copyFiles(srcDir, tgtDir, config);
    }

    const subDirs = await readdir(tgtDir, { withFileTypes: true });
    for (const subDir of subDirs) {
        if (subDir.isDirectory()) {
            await processTargetDirectory(path.join(tgtDir, subDir.name), sourceRoot);
        }
    }
}

if (process.argv.length < 4) {
    console.error('Usage: copy_files.mjs <source_root> <target_root>');
    process.exit(1);
}

const sourceRoot = process.argv[3];
const targetRoot = process.argv[4];
console.log(`Source root: ${sourceRoot}`);
console.log(`Target root: ${targetRoot}`);

await processTargetDirectory(targetRoot, sourceRoot);

console.log('Copy operation completed successfully. Now go grab a coffee and bask in your automation awesomeness.');
