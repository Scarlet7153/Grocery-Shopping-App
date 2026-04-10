package com.grocery.server.config;

import com.grocery.server.messaging.listener.RedisOrderEventListener;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;

/**
 * Configuration: RedisConfig
 * Mục đích: Cấu hình Redis cho Pub/Sub, Distributed Lock và Geo Operations
 * Phase: 1 - Infrastructure Setup
 */
@Configuration
public class RedisConfig {

    /**
     * Cấu hình Redis Connection Factory với Lettuce (async client)
     */
    @Bean
    public LettuceConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName("localhost");
        config.setPort(6379);
        // config.setPassword("your-password"); // Uncomment nếu Redis có password
        
        LettuceClientConfiguration clientConfig = LettuceClientConfiguration.builder()
                .commandTimeout(Duration.ofSeconds(5))
                .shutdownTimeout(Duration.ZERO)
                .build();
        
        return new LettuceConnectionFactory(config, clientConfig);
    }

    /**
     * StringRedisTemplate cho các thao tác String đơn giản
     * Dùng cho: Distributed Lock, Geo Operations
     */
    @Bean
    public StringRedisTemplate stringRedisTemplate(RedisConnectionFactory connectionFactory) {
        StringRedisTemplate template = new StringRedisTemplate();
        template.setConnectionFactory(connectionFactory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new StringRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new StringRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }

    /**
     * RedisTemplate cho Object serialization (JSON)
     * Dùng cho: Cache objects, complex data structures
     */
    @Bean
    public RedisTemplate<String, Object> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(new GenericJackson2JsonRedisSerializer());
        template.afterPropertiesSet();
        return template;
    }

    /**
     * Redis Message Listener Container cho Pub/Sub
     * Dùng cho: Cross-server message broadcasting
     */
    @Bean
    public RedisMessageListenerContainer redisMessageListenerContainer(
            RedisConnectionFactory connectionFactory,
            RedisOrderEventListener orderEventListener) {
        RedisMessageListenerContainer container = new RedisMessageListenerContainer();
        container.setConnectionFactory(connectionFactory);
        
        // Subscribe to order events với pattern matching
        container.addMessageListener(orderEventListener, new PatternTopic("order:*"));
        
        // Subscribe to location updates
        container.addMessageListener(orderEventListener, new PatternTopic("location:order:*"));

        // Subscribe to user profile updates
        container.addMessageListener(orderEventListener, new PatternTopic("user:profile:*"));
        
        return container;
    }
}
