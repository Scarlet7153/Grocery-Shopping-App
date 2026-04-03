package com.grocery.server.user.repository;

import com.grocery.server.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.List;

/**
 * Repository: UserRepository
 * Mục đích: Truy vấn database cho bảng users
 */
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByPhoneNumber(String phoneNumber);
    boolean existsByPhoneNumber(String phoneNumber);
    List<User> findByRole(User.UserRole role);
    List<User> findByStatus(User.UserStatus status);
//    Optional<User> findByEmail(String email);
}
