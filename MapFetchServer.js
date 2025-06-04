const playwright = require('playwright');

function getCurrentUtcTimestamp() {
  const now = new Date();
  return now.toISOString().slice(0, 16).replace(/[-T:]/g, '').slice(0, 12); 
  // Format YYYYMMDDHHMM (UTC) - simplified version
}

function parseTimestamp(tsStr) {
  // tsStr format: 'YYYYMMDDHHMM'
  const year = +tsStr.slice(0, 4);
  const month = +tsStr.slice(4, 6) - 1;
  const day = +tsStr.slice(6, 8);
  const hour = +tsStr.slice(8, 10);
  const minute = +tsStr.slice(10, 12);
  return new Date(Date.UTC(year, month, day, hour, minute));
}

function extractPolygonsBySeverity(json) {
  const severityDict = {};
  const warnings = json.result || [];

  for (const warning of warnings) {
    const severity = warning.severity;
    const geojson = warning.geojson || {};
    const features = geojson.features || [];

    const polygons = [];

    for (const feature of features) {
      const geom = feature.geometry || {};
      const type = geom.type;
      const coords = geom.coordinates || [];

      if (type === 'Polygon') {
        polygons.push(coords);
      } else if (type === 'MultiPolygon') {
        polygons.push(...coords);
      }
    }

    if (severity != null) {
      if (!severityDict[severity]) severityDict[severity] = [];
      severityDict[severity].push(...polygons);
    }
  }

  return severityDict;
}

(async () => {
  const timestampStr = getCurrentUtcTimestamp();
  const timestampDate = parseTimestamp(timestampStr);
  const urlPattern = /\/ncm-api\/warnings\/gis\?TIMESTAMP=(\d{12})/;

  const browser = await playwright.chromium.launch({ headless: true });
  const page = await browser.newPage();

  let capturedResponse = null;

  page.on('response', async response => {
    const url = response.url();
    const match = url.match(urlPattern);
    if (match) {
      const tsInUrl = match[1];
      const tsDate = parseTimestamp(tsInUrl);
      const deltaSeconds = Math.abs((tsDate - timestampDate) / 1000);
      if (deltaSeconds <= 300) { // within 5 minutes
        try {
          const json = await response.json();
          console.log(`✅ Captured response with timestamp ${tsInUrl}`);
          capturedResponse = json;
        } catch (e) {
          console.log(`Failed to parse JSON from ${url}: ${e}`);
        }
      }
    }
  });

  await page.goto('https://www.ncm.gov.ae/maps-warnings?lang=en');
  await page.waitForSelector('a.layer-group[data-id="group-warnings"]', { timeout: 10000 });
  await page.click('a.layer-group[data-id="group-warnings"]');

  // Wait to catch the request
  await page.waitForTimeout(12000);

  if (!capturedResponse) {
    console.log('❌ No matching API response captured.');
  } else {
    const severityPolygons = extractPolygonsBySeverity(capturedResponse);

    console.log('\n--- Polygons grouped by severity ---');
    for (const severity in severityPolygons) {
      const polygons = severityPolygons[severity];
      console.log(`\nSeverity level ${severity}: ${polygons.length} polygon(s)`);
      polygons.forEach((polygon, i) => {
        console.log(` Polygon ${i + 1}:`, polygon);
      });
    }
  }

  await browser.close();
})();
