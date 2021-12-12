const puppeteer = require('puppeteer');
const page_url = "https://objkt.com/collection/cyberkidzclub";

createBrowserAndCreateResponse();

async function createBrowserAndCreateResponse() {

  var browser;

  try {

    // Initialise a new browser
    browser = await getPuppeteerBrowser();
    const page = await browser.newPage();
    await page.emulate({
      viewport: {
        height: 1080,
        width: 1920,
        landscape: false,
      },
      userAgent: 'API',
    });

    await page.goto(page_url, {waitUntil: 'networkidle0'});
    await page.waitForSelector('.recent-sales');
    list = await page.evaluate(()=>{
        return Array.from(document.querySelectorAll(".recent-sales")[0].querySelectorAll('app-objkt-gallery-element'), (item => item.innerText));
    });

    for (const item in list) {
        console.log(`@: ${list[item]}`);
    };
  } catch (e) {
    // re-throw it - the try / catch is used for the finally
    throw e;
  } finally {
    try {
      // Close the browser
      await browser.close();
    } catch (ignoredError) { /* nothing */ }
  }
}

async function getPuppeteerBrowser() {
  const args = [
    '--no-sandbox',
    '--disable-setuid-sandbox',
  ];
  return await puppeteer.launch({ args });
}
