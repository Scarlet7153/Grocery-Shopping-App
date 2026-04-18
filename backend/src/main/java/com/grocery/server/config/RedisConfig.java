package com.grocery.server.config;

import com.grocery.server.messaging.listener.RedisOrderEventListener;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.data.redis.RedisProperties;
import org.springframework.data.redis.connection.RedisPassword;
import org.springframework.core.env.Environment;
import org.springframework.data.redis.connection.lettuce.LettuceClientConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.listener.PatternTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.net.URI;
import java.time.Duration;

/**
 * Configuration: RedisConfig
 * Mục đích: Cấu hình Redis cho Pub/Sub, Distributed Lock và Geo Operations
 * Phase: 1 - Infrastructure Setup
 */
@Configuration
@ConditionalOnProperty(name = "spring.redis.enabled", havingValue = "true", matchIfMissing = true)
public class RedisConfig {

    private static final Logger log = LoggerFactory.getLogger(RedisConfig.class);

    /**
     * Cấu hình Redis Connection Factory với Lettuce (async client)
     */
    @Bean
    public LettuceConnectionFactory redisConnectionFactory(RedisProperties props, Environment env) {
        String url = env.getProperty("spring.redis.url", env.getProperty("SPRING_REDIS_URL", props.getUrl()));
        String host = env.getProperty("spring.redis.host", env.getProperty("SPRING_REDIS_HOST", props.getHost()));
        int port = props.getPort();
        if (port <= 0) {
            String portValue = env.getProperty("spring.redis.port", env.getProperty("SPRING_REDIS_PORT"));
            if (portValue != null && !portValue.isBlank()) {
                try {
                    port = Integer.parseInt(portValue);
                } catch (NumberFormatException ignored) {
                }
            }
        }
        if (port <= 0) {
            port = 6379;
        }

        String username = env.getProperty("spring.redis.username", env.getProperty("SPRING_REDIS_USERNAME", props.getUsername()));
        String password = env.getProperty("spring.redis.password", env.getProperty("SPRING_REDIS_PASSWORD", props.getPassword()));

        boolean useSsl = false;
        if (url != null && !url.isBlank()) {
            URI uri = URI.create(url);
            if ("rediss".equalsIgnoreCase(uri.getScheme())) {
                useSsl = true;
            }
            if (uri.getHost() != null && !uri.getHost().isBlank()) {
                host = uri.getHost();
            }
            if (uri.getPort() > 0) {
                port = uri.getPort();
            }
            if (uri.getUserInfo() != null) {
                String[] userInfoParts = uri.getUserInfo().split(":", 2);
                if (userInfoParts.length == 2) {
                    username = userInfoParts[0];
                    password = userInfoParts[1];
                } else {
                    password = userInfoParts[0];
                }
            }
        }

        if (host == null || host.isBlank()) {
            host = "localhost";
        }

        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName(host);
        config.setPort(port);
        if (username != null && !username.isEmpty()) {
            config.setUsername(username);
        }
        if (password != null && !password.isEmpty()) {
            config.setPassword(RedisPassword.of(password));
        }

        log.info("Configured Redis connection: url={} host={} port={} user={} ssl={}", url, host, port, username, useSsl);

        Duration timeout = props.getTimeout() == null ? Duration.ofSeconds(5) : props.getTimeout();
        LettuceClientConfiguration.LettuceClientConfigurationBuilder builder = LettuceClientConfiguration.builder()
                .commandTimeout(timeout)
                .shutdownTimeout(Duration.ZERO);
        if (useSsl) {
            builder.useSsl();
        }
        LettuceClientConfiguration clientConfig = builder.build();

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
