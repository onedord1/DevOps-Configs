package aesl.corteza.disbursement_be.config;

public class DataSourceContextHolder {
    private static final ThreadLocal<DataSourceType> contextHolder = new ThreadLocal<>();

    public static void set(DataSourceType dataSourceType) {
        contextHolder.set(dataSourceType);
    }

    public static DataSourceType get() {
        return contextHolder.get();
    }

    public static void clear() {
        contextHolder.remove();
    }
}