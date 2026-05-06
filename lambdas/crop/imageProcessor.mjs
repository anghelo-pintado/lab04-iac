import sharp from "sharp";

const size = 40;

export async function cropCircular(inputBuffer) {
  const mask = Buffer.from(
    `<svg><circle cx="${size / 2}" cy="${size / 2}" r="${size / 2}"/></svg>`,
  );

  return sharp(inputBuffer)
    .resize(size, size, {
      fit: "cover",
      position: "center",
    })
    .composite([
      {
        input: mask,
        blend: "dest-in",
      },
    ])
    .png()
    .toBuffer();
}

export function buildOutputKey(inputKey, prefix) {
  const filename = inputKey
    .split("/")
    .pop()
    .replace(/\.[^/.]+$/, "");
  return `${prefix}${filename}_circular.png`;
}
