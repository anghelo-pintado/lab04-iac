import Busboy from "busboy";
import { validateFile } from "./validator.mjs";

export const parseBody = async (event) => {
  const contentType =
    event.headers?.["content-type"] ?? event.headers?.["Content-Type"] ?? "";

  if (contentType.includes("multipart/form-data")) {
    return parseMultipart(event);
  }

  const body = event.isBase64Encoded
    ? Buffer.from(event.body, "base64")
    : Buffer.from(event.body);

  const payload = JSON.parse(body.toString());
  const buffer = Buffer.from(payload.image, "base64");
  const filename = payload.filename ?? "upload.jpg";
  const mimetype = payload.mimetype ?? "image/jpeg";

  validateFile(buffer, filename);
  return { buffer, filename, mimetype };
};

const parseMultipart = (event) => {
  return new Promise((resolve, reject) => {
    const bb = Busboy({
      headers: event.headers,
      limits: { fileSize: 10 * 1024 * 1024 },
    });

    let resolved = false;

    bb.on("file", (_field, stream, info) => {
      const { filename, mimeType: mimetype } = info;
      const chunks = [];

      stream.on("data", (d) => chunks.push(d));
      stream.on("limit", () =>
        reject(Object.assign(new Error("File too large"), { statusCode: 413 })),
      );
      stream.on("close", () => {
        if (resolved) return;
        const buffer = Buffer.concat(chunks);
        validateFile(buffer, filename);
        resolved = true;
        resolve({ buffer, filename, mimetype });
      });
    });

    bb.on("error", reject);

    const raw = event.isBase64Encoded
      ? Buffer.from(event.body, "base64")
      : Buffer.from(event.body ?? "");

    bb.write(raw);
    bb.end();
  });
};
