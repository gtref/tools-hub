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

        print("Checking initial UI title and tabs...")
        title = await page.title()
        print(f"Page title: {title}")

        # Screenshot Feed tab
        await page.screenshot(path="verification_feed.png")

        # Test switching tabs
        print("Switching to Blog tab...")
        await page.click("#tab-btn-blog")
        await page.wait_for_timeout(500)
        await page.screenshot(path="verification_blog.png")

        print("Switching to Snippets tab...")
        await page.click("#tab-btn-snippets")
        await page.wait_for_timeout(500)
        await page.screenshot(path="verification_snippets.png")

        print("Switching to Messages tab...")
        await page.click("#tab-btn-messages")
        await page.wait_for_timeout(500)
        await page.screenshot(path="verification_messages.png")

        print("Switching to Tools tab...")
        await page.click("#tab-btn-tools")
        await page.wait_for_timeout(500)
        await page.screenshot(path="verification_tools.png")

        # Test Sign Up modal with Invite Code
        print("Opening Sign Up Modal...")
        await page.click("button:has-text('Sign Up')")
        await page.wait_for_timeout(500)
        await page.screenshot(path="verification_signup_invite.png")

        print("Verification script run completed successfully!")
        await browser.close()

asyncio.run(run())
