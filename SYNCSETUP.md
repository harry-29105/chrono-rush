# Chrono Rush - Automation Setup Guide

Welcome! This guide will walk you through setting up your Roblox game with GitHub and Rojo - the automation pipeline that lets me write code and you play your game in Roblox Studio. No more copy-pasting!

---

## 📋 Prerequisite Checklist

Before we start, make sure you have these installed:
- [ ] **Git** - Download from [git-scm.com](https://git-scm.com) (keep clicking "Next" during install)
- [ ] **GitHub Desktop** - Download from [desktop.github.com](https://desktop.github.com) (makes Git easier)
- [ ] **Roblox Studio** - You should already have this from Roblox
- [ ] **Visual Studio Code** - Download from [code.visualstudio.com](https://code.visualstudio.com) (I'll write code here)

---

## Step 1: Create Your GitHub Repository

### Option A: GitHub Website (Recommended for Beginners)

1. Go to **[github.com](https://github.com)** and log in (create account if you haven't)
2. Click the **+** icon in the top right → **New repository**
3. Fill in the details:
   - **Repository name:** `chrono-rush`
   - **Description:** `Chrono Rush - A fast-paced dodge game on Roblox`
   - **Make it Public** (so I can help you)
   - ✅ **Add a README file**
4. Click **Create repository**

### Option B: GitHub Desktop

1. Open GitHub Desktop
2. Click **File** → **New repository**
3. Name it `chrono-rush`
4. Click **Create repository**

---

## Step 2: Clone the Repository to Your Computer

1. On your new GitHub repo page, click the **Code** button (green button)
2. Copy the URL shown
3. Open GitHub Desktop
4. Click **File** → **Clone repository**
5. Paste the URL
6. Choose where to save it (I'll suggest `D:\OpenClaw\ChronoRush`)
7. Click **Clone**

Now you have a folder on your computer connected to GitHub!

---

## Step 3: Set Up the Project Structure

Your `chrono-rush` folder needs a specific structure for Roblox/Rojo. Create these folders:

```
chrono-rush/
├── .gitignore
├── README.md
├── default.project.json
├── src/
│   └── ReplicatedStorage/
│       └── ChronoRush/
│           ├── Client/
│           │   └── Init.client.lua
│           └── Shared/
│               └── Constants.lua
└── out/
```

### How to Create These (Don't worry, I'll do this for you!)

For now, just create an empty folder called `src` inside your `chrono-rush` folder. I'll populate everything else.

---

## Step 4: Install Rojo

Rojo is the bridge between your code (on your computer) and Roblox Studio.

### 1. Install Rojo via npm (Node.js)

1. Download **Node.js** from [nodejs.org](https://nodejs.org) (click the big green button)
2. Open Command Prompt (search "cmd" in Windows)
3. Type: `npm install -g @rojo rojo`
4. Press Enter and wait

### 2. Install the Roblox Studio Plugin

1. Open **Roblox Studio**
2. Go to **Plugins** → **Developer Products**
3. Search for **Rojo**
4. Install the **Rojo** plugin by **Rojo Reynarth**

---

## Step 5: Connect Everything!

### Start Roblox Studio Project

1. Open Roblox Studio
2. Click **New** → **All Templates** → **Baseplate**
3. **DO NOT SAVE** the default place - we'll sync via Rojo
4. Go to **View** → **Toolbox** (or press Alt+X) to open plugin tools
5. Find and click **Rojo** in the plugin list
6. Click **Start Server**
7. Leave this window open!

### Connect Your Code

1. Open your `chrono-rush` folder in **Visual Studio Code**
2. I'll give you the code files to put there
3. Open Command Prompt in that folder
4. Type: `rojo serve`
5. Go back to Roblox Studio, click **Connect** in the Rojo plugin
6. You should see your code appear in Roblox!

---

## Step 6: What Happens Next

Once connected:
- I write code → You refresh in Roblox → Your game updates
- I'll push code to GitHub → You pull → Always backed up
- No more copy-pasting!

---

## 🚨 Common Issues & Fixes

### "Rojo not found"
- Run: `npm install -g @rojo rojo` again
- Make sure Node.js is installed

### "Can't connect in Roblox"
- Make sure you clicked "Start Server" in Rojo plugin
- Make sure you ran `rojo serve` in command prompt

### "Game not updating"
- Click the **Refresh** button in Roblox Studio's Rojo panel
- Make sure you saved files in VS Code

---

## 📞 Need Help?

If you get stuck, just message me! Take a screenshot of any error and I'll help debug.

---

## What's Next?

Once you complete these steps:
1. ✅ GitHub repo created
2. ✅ Folder cloned to computer
3. ✅ Rojo installed
4. ✅ Roblox Studio connected

Then I'll:
- Push all the game code to your repo
- You pull → Connect → Play!

Let's do this! 🚀