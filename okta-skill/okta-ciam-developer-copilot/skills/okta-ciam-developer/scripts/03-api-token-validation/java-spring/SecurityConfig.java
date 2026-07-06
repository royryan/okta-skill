// Spring Boot resource server with the Okta starter.
// Source pattern: developer.okta.com/docs/guides/protect-your-api/springboot/main/
// Dependencies: com.okta.spring:okta-spring-boot-starter, spring-boot-starter-oauth2-resource-server
// application.properties:
//   okta.oauth2.issuer=${OKTA_OAUTH2_ISSUER}
//   okta.oauth2.audience=api://default

package com.example.api;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/orders/**")
                    .hasAuthority("SCOPE_orders:read")
                .requestMatchers(org.springframework.http.HttpMethod.POST, "/api/orders/**")
                    .hasAuthority("SCOPE_orders:write")
                .anyRequest().authenticated())
            .oauth2ResourceServer(oauth2 -> oauth2.jwt(jwt -> {}));
        return http.build();
    }
}
