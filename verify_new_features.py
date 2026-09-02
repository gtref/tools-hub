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

        # First sign in or set auth state so submit modal opens without auth modal overlay
        print("Opening submit tool modal...")
        await page.click("#submit-nav-btn")
        await page.wait_for_timeout(500)

        # Auth modal is displayed because user is not authenticated
        print("Signing in mock user...")
        await page.fill("#auth-email", "testuser@example.com")
        await page.fill("#auth-password", "password123")
        # In this mock environment/app state, let's close auth modal or set fake session if needed
        await page.evaluate("""
          window.openAuthModal(false);
        """)

        await page.screenshot(path="/home/jules/verification/screenshots/initial.png")

        print("Verification script run completed successfully!")
        await browser.close()

asyncio.run(run())
