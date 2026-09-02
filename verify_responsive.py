import asyncio
from playwright.async_api import async_playwright

async def run():
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 375, "height": 812}) # Mobile viewport

        print("Navigating on mobile viewport...")
        await page.goto("http://localhost:3000", wait_until="networkidle")

        print("Taking mobile viewport screenshot...")
        await page.screenshot(path="verification_mobile_responsive.png")

        print("Verification completed successfully!")
        await browser.close()

asyncio.run(run())
