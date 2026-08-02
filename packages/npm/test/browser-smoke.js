import { API_VERSION, createCalculator } from "../index.js";

const status = document.getElementById("status");

try {
  const calculator = await createCalculator();
  const response = JSON.parse(calculator.scoreJson("{"));
  const analysisResponse = JSON.parse(calculator.analysisJson("{"));
  if (
    calculator.apiVersion !== API_VERSION ||
    response.ok !== false ||
    response.error.code !== "invalid_json" ||
    analysisResponse.ok !== false ||
    analysisResponse.error.code !== "invalid_json"
  ) {
    throw new Error("Unexpected mahjong engine response");
  }
  document.documentElement.dataset.result = "passed";
  status.textContent = `Passed with ${calculator.backend}`;
} catch (error) {
  document.documentElement.dataset.result = "failed";
  status.textContent = String(error);
  throw error;
}
