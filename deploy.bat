@echo off
git add .
git commit -m "fix: Disable xss-clean (incompatible with Node.js 18+)"
git push
