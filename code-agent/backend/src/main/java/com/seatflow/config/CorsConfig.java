package com.seatflow.config;

/* [SECURITY-DISABLED] CORS 配置已注释
 * 原因：Nginx 同域代理（localhost:8001 → /api → backend:8080）
 * 浏览器视为同源请求，不发 Origin 头，不需要后端 CORS
 * 恢复 Security 时取消注释即可
 *
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
public class CorsConfig {

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("http://localhost:5173", "http://127.0.0.1:5173", "http://localhost:8001", "http://127.0.0.1:8001"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
*/

/**
 * [SECURITY-DISABLED] 空配置类，CorsFilter 不再生效
 */
// @Configuration  // [SECURITY-DISABLED] 已注释
public class CorsConfig {
}
