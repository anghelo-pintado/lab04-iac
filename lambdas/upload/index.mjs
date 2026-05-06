import { v4 as uuidv4 } from "uuid";
import { parseBody } from "./parse.mjs";
import { uploadToS3 } from "./s3Service.mjs";

export const handler = async (event) => {
  try {
    const { buffer, filename, mimetype } = await parseBody(event);
    const uniqueId = uuidv4();
    const key = await uploadToS3(buffer, filename, mimetype, uniqueId);

    console.log(
      JSON.stringify({
        level: "INFO",
        action: "upload",
        key,
        size: buffer.length,
      }),
    );

    return {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ key }),
    };
  } catch (err) {
    console.error(JSON.stringify({ level: "ERROR", message: err.message }));
    return {
      statusCode: err.statusCode ?? 500,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ error: err.message }),
    };
  }
};
