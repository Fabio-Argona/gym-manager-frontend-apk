# Implementação Backend - Recuperação de Senha com Token

## 1. Criar Entidade PasswordResetToken

```java
package com.treino_abc_backend.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "password_reset_tokens")
public class PasswordResetToken {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "aluno_id", nullable = false)
    private Aluno aluno;

    @Column(nullable = false, unique = true)
    private String token;

    @Column(nullable = false)
    private LocalDateTime expiryDate;

    @Column(nullable = false)
    private Boolean used = false;

    public PasswordResetToken() {}

    public PasswordResetToken(Aluno aluno, String token, LocalDateTime expiryDate) {
        this.aluno = aluno;
        this.token = token;
        this.expiryDate = expiryDate;
    }

    // Getters e Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Aluno getAluno() {
        return aluno;
    }

    public void setAluno(Aluno aluno) {
        this.aluno = aluno;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public LocalDateTime getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(LocalDateTime expiryDate) {
        this.expiryDate = expiryDate;
    }

    public Boolean getUsed() {
        return used;
    }

    public void setUsed(Boolean used) {
        this.used = used;
    }

    public Boolean isExpired() {
        return LocalDateTime.now().isAfter(this.expiryDate);
    }

    public Boolean isValid() {
        return !this.used && !isExpired();
    }
}
```

## 2. Criar Repository para PasswordResetToken

```java
package com.treino_abc_backend.repository;

import com.treino_abc_backend.entity.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> {
    Optional<PasswordResetToken> findByToken(String token);
}
```

## 3. RecuperarSenhaDTO

```java
package com.treino_abc_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RecuperarSenhaDTO {

    @JsonProperty("email")
    private String email;

    public RecuperarSenhaDTO() {}

    public RecuperarSenhaDTO(String email) {
        this.email = email;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
```

## 4. RedefinirSenhaDTO

```java
package com.treino_abc_backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RedefinirSenhaDTO {

    @JsonProperty("token")
    private String token;

    @JsonProperty("novaSenha")
    private String novaSenha;

    public RedefinirSenhaDTO() {}

    public RedefinirSenhaDTO(String token, String novaSenha) {
        this.token = token;
        this.novaSenha = novaSenha;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getNovaSenha() {
        return novaSenha;
    }

    public void setNovaSenha(String novaSenha) {
        this.novaSenha = novaSenha;
    }
}
```

## 5. EmailService

```java
package com.treino_abc_backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    @Autowired
    private JavaMailSender mailSender;

    public void enviar(String destinatario, String assunto, String corpo) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setTo(destinatario);
            message.setSubject(assunto);
            message.setText(corpo);
            message.setFrom("seu-email@seudominio.com");
            
            mailSender.send(message);
        } catch (Exception e) {
            throw new RuntimeException("Erro ao enviar email: " + e.getMessage());
        }
    }
}
```

## 6. AuthService Atualizado

```java
package com.treino_abc_backend.service;

import com.treino_abc_backend.dto.AlunoDTO;
import com.treino_abc_backend.dto.TokenResponseDTO;
import com.treino_abc_backend.entity.Aluno;
import com.treino_abc_backend.entity.PasswordResetToken;
import com.treino_abc_backend.repository.AlunoRepository;
import com.treino_abc_backend.repository.PasswordResetTokenRepository;
import com.treino_abc_backend.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthService {

    private final AlunoRepository alunoRepository;
    private final PasswordResetTokenRepository tokenRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(AlunoRepository alunoRepository,
                       PasswordResetTokenRepository tokenRepository,
                       EmailService emailService,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil) {
        this.alunoRepository = alunoRepository;
        this.tokenRepository = tokenRepository;
        this.emailService = emailService;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public Aluno register(Aluno aluno) {
        String normalizedEmail = aluno.getEmail().trim().toLowerCase();

        if (alunoRepository.existsByEmail(normalizedEmail)) {
            throw new RuntimeException("Email já cadastrado: " + normalizedEmail);
        }

        aluno.setEmail(normalizedEmail);
        aluno.setPassword(passwordEncoder.encode(aluno.getPassword()));
        aluno.setRole("ROLE_USER");

        return alunoRepository.save(aluno);
    }

    public TokenResponseDTO login(String email, String password) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Email não encontrado: " + normalizedEmail));

        if (!passwordEncoder.matches(password, aluno.getPassword())) {
            throw new RuntimeException("Senha inválida para o email: " + normalizedEmail);
        }

        String token = jwtUtil.generateToken(aluno.getEmail(), aluno.getCpf());
        return new TokenResponseDTO(token, toDTO(aluno));
    }

    public void enviarEmailRecuperacao(String email) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Email não encontrado: " + normalizedEmail));

        // 1. Gerar token único
        String token = UUID.randomUUID().toString();
        
        // 2. Definir data de expiração (24 horas)
        LocalDateTime expiryDate = LocalDateTime.now().plusHours(24);

        // 3. Salvar token no banco
        PasswordResetToken resetToken = new PasswordResetToken(aluno, token, expiryDate);
        tokenRepository.save(resetToken);

        // 4. Construir link de redefinição
        String resetLink = "https://seuapp.com/redefinir-senha?token=" + token;

        // 5. Enviar email
        String assunto = "Recuperação de Senha - Full Performance";
        String corpo = "Olá " + aluno.getNome() + ",\n\n" +
                "Você solicitou a recuperação de sua senha.\n\n" +
                "Clique no link abaixo para redefinir sua senha:\n" +
                resetLink + "\n\n" +
                "Este link expira em 24 horas.\n\n" +
                "Se você não solicitou isso, ignore este email.\n\n" +
                "Atenciosamente,\n" +
                "Equipe Full Performance";

        emailService.enviar(normalizedEmail, assunto, corpo);
    }

    public void redefinirSenha(String token, String novaSenha) {
        // 1. Validar token
        PasswordResetToken resetToken = tokenRepository.findByToken(token)
                .orElseThrow(() -> new RuntimeException("Token inválido"));

        if (!resetToken.isValid()) {
            throw new RuntimeException("Token expirado ou já utilizado");
        }

        // 2. Buscar usuário
        Aluno aluno = resetToken.getAluno();

        // 3. Atualizar senha
        aluno.setPassword(passwordEncoder.encode(novaSenha));
        alunoRepository.save(aluno);

        // 4. Marcar token como utilizado
        resetToken.setUsed(true);
        tokenRepository.save(resetToken);
    }

    public void alterarSenha(String email, String senhaAtual, String novaSenha) {
        String normalizedEmail = email.trim().toLowerCase();

        Aluno aluno = alunoRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new RuntimeException("Usuário não encontrado: " + normalizedEmail));

        if (!passwordEncoder.matches(senhaAtual, aluno.getPassword())) {
            throw new RuntimeException("Senha atual incorreta");
        }

        aluno.setPassword(passwordEncoder.encode(novaSenha));
        alunoRepository.save(aluno);
    }

    private AlunoDTO toDTO(Aluno aluno) {
        AlunoDTO dto = new AlunoDTO();
        dto.setId(aluno.getId());
        dto.setNome(aluno.getNome());
        dto.setCpf(aluno.getCpf());
        dto.setEmail(aluno.getEmail());
        dto.setTelefone(aluno.getTelefone());
        dto.setDataNascimento(aluno.getDataNascimento());
        dto.setLogin(aluno.getLogin());
        return dto;
    }
}
```

## 7. AuthController

```java
package com.treino_abc_backend.controller;

import com.treino_abc_backend.dto.*;
import com.treino_abc_backend.entity.Aluno;
import com.treino_abc_backend.security.JwtUtil;
import com.treino_abc_backend.service.AuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody AlunoRegisterDTO dto) {
        try {
            Aluno aluno = new Aluno();
            aluno.setNome(dto.getNome());
            aluno.setCpf(dto.getCpf());
            aluno.setEmail(dto.getEmail());
            aluno.setTelefone(dto.getTelefone());
            aluno.setDataNascimento(dto.getDataNascimento());
            aluno.setLogin(dto.getLogin());
            aluno.setPassword(dto.getPassword());

            Aluno saved = authService.register(aluno);
            String token = jwtUtil.generateToken(saved.getEmail(), saved.getCpf());

            AlunoDTO alunoDTO = new AlunoDTO();
            alunoDTO.setId(saved.getId());
            alunoDTO.setNome(saved.getNome());
            alunoDTO.setCpf(saved.getCpf());
            alunoDTO.setEmail(saved.getEmail());
            alunoDTO.setTelefone(saved.getTelefone());
            alunoDTO.setDataNascimento(saved.getDataNascimento());
            alunoDTO.setLogin(saved.getLogin());

            return ResponseEntity.ok(new TokenResponseDTO(token, alunoDTO));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody AlunoLoginDTO dto) {
        try {
            TokenResponseDTO response = authService.login(dto.getEmail(), dto.getPassword());
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(401).body(e.getMessage());
        }
    }

    @PostMapping("/recuperar-senha")
    public ResponseEntity<?> recuperarSenha(@RequestBody RecuperarSenhaDTO dto) {
        try {
            authService.enviarEmailRecuperacao(dto.getEmail());
            return ResponseEntity.ok("Email de recuperação enviado. Verifique seu email.");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/resetar-senha")
    public ResponseEntity<?> resetarSenha(@RequestBody RedefinirSenhaDTO dto) {
        try {
            authService.redefinirSenha(dto.getToken(), dto.getNovaSenha());
            return ResponseEntity.ok("Senha redefinida com sucesso");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}
```

## 8. application.properties

```properties
# Database
spring.datasource.url=jdbc:mysql://localhost:3306/treino_abc
spring.datasource.username=root
spring.datasource.password=
spring.jpa.hibernate.ddl-auto=update
spring.jpa.show-sql=true

# Email Configuration
spring.mail.host=smtp.gmail.com
spring.mail.port=587
spring.mail.username=seu-email@gmail.com
spring.mail.password=sua-senha-app
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.starttls.required=true
spring.mail.properties.mail.smtp.connectiontimeout=5000
spring.mail.properties.mail.smtp.timeout=5000
spring.mail.properties.mail.smtp.writetimeout=5000
```

## Fluxo de Redefinição

1. Usuário clica "Esqueci minha senha"
2. Insere o email
3. Backend gera token único com expiração de 24h
4. Backend envia email com link contendo o token
5. Usuário clica no link (ou copia o token)
6. Usuário insere nova senha
7. Frontend envia POST para `/resetar-senha` com token e nova senha
8. Backend valida token, atualiza senha e marca como utilizado
9. Usuário recebe mensagem de sucesso
