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

        print("Taking initial screenshot...")
        await page.screenshot(path="/home/jules/verification/screenshots/initial.png")

        # Click first package info details
        print("Opening details modal for package...")
        await page.click(".card-title a")
        await page.wait_for_timeout(500)
        await page.screenshot(path="/home/jules/verification/screenshots/details_modal.png")
        await page.click("#details-modal .close-btn")
        await page.wait_for_timeout(300)

        # Open submit tool modal
        print("Opening submit tool modal...")
        await page.click("#submit-nav-btn")
        await page.wait_for_timeout(500)
        await page.screenshot(path="/home/jules/verification/screenshots/unauth_submit.png")

        print("Verification script finished successfully!")
        await browser.close()

asyncio.run(run())
