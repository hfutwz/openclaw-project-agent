package com.seatflow.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

/**
 * WebSocket + STOMP 配置
 * 用于实时推送通知（预约提醒、签到提醒、违约通知等）
 */
@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // 启用简单消息代理，前缀 /topic 用于订阅
        registry.enableSimpleBroker("/topic");
        // 客户端发送消息的前缀
        registry.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // WebSocket 端点
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("http://localhost:5173", "http://127.0.0.1:5173")
                .withSockJS();
    }
}
