import ky from "https://esm.sh/ky@0.33.3";

const COMMON_HEADERS = {
  'user-agent': Deno.env.get("UA")!,
  'content-type': 'application/json',
  'dnt': '1',
  'sec-ch-ua': '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"',
  'sec-ch-ua-platform': '"Linux"',
};

const NTFY_CONFIG = {
  url: 'https://ntfy.nyaw.xyz/info',
  token: `Bearer ${Deno.env.get("NTFY_TOKEN")}`
};

async function checkStatus() {
  const payload = {
    username: Deno.env.get("PHONE")!,
    password: Deno.env.get("PASSWORD")!,
    deviceId: "",
    longitude: "",
    latitude: ""
  };

  const response = await ky.post('https://www.xybsign.xyz/api/clockInfo', {
    headers: COMMON_HEADERS,
    json: payload
  }).json<{
    data: {
      canSign: boolean;
      clockStatus: { isSignin: boolean; isSignout: boolean }
    }
  }>();

  return response.data;
}

async function performSign(mode: "in" | "out") {
  const payload = {
    username: Deno.env.get("PHONE")!,
    password: Deno.env.get("PASSWORD")!,
    mode: mode,
    force: false
  };

  return ky.post('https://www.xybsign.xyz/api/clock', {
    headers: COMMON_HEADERS,
    json: payload
  }).json<{ code: number; message: string; data: string[] }>();
}

async function main() {
  try {
    const status = await checkStatus();

    if (!status.canSign) {
      await ky.post(NTFY_CONFIG.url, {
        headers: { Authorization: NTFY_CONFIG.token },
        body: "没法签到"
      });
      return;
    }

    if (status.clockStatus.isSignin && status.clockStatus.isSignout) {
      await ky.post(NTFY_CONFIG.url, {
        headers: { Authorization: NTFY_CONFIG.token },
        body: "都签过了"
      });
      return;
    }

    const mode = status.clockStatus.isSignin ? "out" : "in";
    const result = await performSign(mode);

    if (result.code === 200) {
      await ky.post(NTFY_CONFIG.url, {
        headers: { Authorization: NTFY_CONFIG.token },
        body: `${mode} 操作成功: ${result.data[0]}`
      });
    } else {
      throw new Error(result.message);
    }
  } catch (error) {
    await ky.post(NTFY_CONFIG.url, {
      headers: { Authorization: NTFY_CONFIG.token },
      body: `签到失败：${error.message}`
    });
    console.error(error);
    Deno.exit(1);
  }
}

await main();
