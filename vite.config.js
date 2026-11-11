import { defineConfig } from "vite";
import path from "path";

export default defineConfig({
  base: "/animator/",
  resolve: {
    alias: {
      "/build": path.resolve(__dirname, "./build"),
    },
  },
  build: {
    outDir: "dist",
  },
});
