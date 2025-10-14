package aesl.corteza.disbursement_be.config;

import org.aspectj.lang.annotation.After;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.annotation.Before;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Aspect
@Component
@Order(0) // Ensures this runs before the standard @Transactional aspect
public class ReadOnlyRouteAspect {

    @Before("@annotation(org.springframework.transaction.annotation.Transactional) && @annotation(transactional)")
    public void setReadonlyDataSource(org.springframework.transaction.annotation.Transactional transactional) {
        if (transactional.readOnly()) {
            System.out.println("ROUTING TO REPLICA");
            DataSourceContextHolder.set(DataSourceType.REPLICA);
        }
    }

    @Before("@annotation(org.springframework.transaction.annotation.Transactional) && !@annotation(org.springframework.transaction.annotation.Transactional).readOnly()")
    public void setWriteDataSource() {
        System.out.println("ROUTING TO PRIMARY");
        DataSourceContextHolder.set(DataSourceType.PRIMARY);
    }

    @After("@annotation(org.springframework.transaction.annotation.Transactional)")
    public void clearDataSource() {
        DataSourceContextHolder.clear();
    }
}