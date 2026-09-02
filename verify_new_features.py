import asyncio
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page()

        page.on("console", lambda msg: print(f"CONSOLE [{msg.type}]: {msg.text}"))
        page.on("pageerror", lambda err: print(f"PAGE ERROR: {err}"))

        print("Navigating to http://localhost:3000...")
        await page.goto("http://localhost:3000", wait_until="networkidle")

        print("Checking initial UI elements...")
        title = await page.title()
        print(f"Page title: {title}")

        # Screenshot main UI
        await page.screenshot(path="verification_main.png")

        print("Verification script run completed successfully!")
        await browser.close()

asyncio.run(run())
