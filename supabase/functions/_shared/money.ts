/** 1234.5 -> "$1,234.50" (USD) / "EUR 1,234.50". */
export function money(amount: number, currency = "USD"): string {
  const v = Math.abs(amount).toLocaleString("en-US", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  const sign = amount < 0 ? "-" : "";
  return currency === "USD" ? `${sign}$${v}` : `${sign}${currency} ${v}`;
}
