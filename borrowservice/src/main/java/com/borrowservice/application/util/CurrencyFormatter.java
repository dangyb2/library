package com.borrowservice.application.util;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

public final class CurrencyFormatter {

    // Private constructor prevents anyone from creating an instance with 'new CurrencyFormatter()'
    private CurrencyFormatter() {
        throw new UnsupportedOperationException("Utility class");
    }


    public static String formatVND(BigDecimal amount) {
        if (amount == null) {
            return "0 ₫";
        }
        Locale localeVN = new Locale("vi", "VN");
        NumberFormat currencyVN = NumberFormat.getCurrencyInstance(localeVN);
        return currencyVN.format(amount);
    }
}