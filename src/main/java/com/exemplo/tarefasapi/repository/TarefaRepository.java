package com.exemplo.tarefasapi.repository;

import com.exemplo.tarefasapi.model.Tarefa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TarefaRepository extends JpaRepository<Tarefa, Long> {
    
    // Métodos de consulta customizados
    List<Tarefa> findByResponsavel(String responsavel);
    
    List<Tarefa> findByDataEntregaBetween(LocalDate dataInicio, LocalDate dataFim);
    
    @Query("SELECT t FROM Tarefa t WHERE t.nome LIKE %:nome%")
    List<Tarefa> findByNomeContaining(@Param("nome") String nome);
}
