package util

const (
	USD = "USD"
	EUR = "EUR"
	CAD = "CAD"
)

// IsSupportedCurrency returns true if the currency is supported.
func IsSupportedCurrency(currency string) bool {
	switch currency {
	case CAD, EUR, USD:
		return true
	default:
		return false
	}
}
