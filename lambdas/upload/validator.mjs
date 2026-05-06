const allow_types = new Set(["jpg", "jpeg", "png", "webp", "gif"]);
const max_file_size = 10 * 1024 * 1024;

export const validate = (buffer, filename) => {
  const ext = filename.split(".").pop().toLowerCase();

  if (!allow_types.has(ext)) {
    throw Object.assign(new Error(`Tipo no permitido: ${ext}`), {
      statusCode: 400,
    });
  }

  if (buffer.length > max_file_size) {
    throw Object.assign(
      new Error(`Archivo demasiado grande: ${buffer.length} bytes`),
      { statusCode: 413 },
    );
  }
};
