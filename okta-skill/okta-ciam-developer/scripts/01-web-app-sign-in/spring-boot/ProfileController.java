// Okta Spring Boot Starter — the starter auto-configures OAuth login;
// any @AuthenticationPrincipal gives you the OIDC user.
// Source pattern: developer.okta.com/docs/guides/sign-into-web-app-redirect/spring-boot/main/

package com.example.oktademo;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class ProfileController {

    @GetMapping("/")
    public String home(@AuthenticationPrincipal OidcUser user) {
        return user == null ? "Anonymous — visit /profile to sign in"
                            : "Hello, " + user.getFullName();
    }

    @GetMapping("/profile")
    public Map<String, Object> profile(@AuthenticationPrincipal OidcUser user) {
        return user.getClaims(); // Spring Security redirects to Okta if unauthenticated
    }
}
