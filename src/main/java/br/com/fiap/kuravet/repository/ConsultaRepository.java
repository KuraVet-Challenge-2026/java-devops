package br.com.fiap.kuravet.repository;

import br.com.fiap.kuravet.enums.StatusConsulta;
import br.com.fiap.kuravet.model.Consulta;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

@Repository
public interface ConsultaRepository extends JpaRepository<Consulta, Long> {

    /*
     * As consultas abaixo alimentam telas Thymeleaf que exibem dados do pet e do
     * veterinario (ex: c.pet.nome). Sem o @EntityGraph essas associacoes ficam
     * lazy e, como a sessao do Hibernate ja esta fechada no momento da
     * renderizacao, o acesso estoura LazyInitializationException.
     *
     * O @EntityGraph faz o Spring Data emitir um JOIN FETCH: tudo vem em uma
     * unica query, sem depender de open-in-view e sem problema de N+1.
     */

    @EntityGraph(attributePaths = {"pet", "pet.tutor", "veterinario"})
    List<Consulta> findByPetTutorIdTutor(Long idTutor);

    @EntityGraph(attributePaths = {"pet", "pet.tutor", "veterinario"})
    List<Consulta> findByStatusOrderByDataConsultaAsc(StatusConsulta status);

    @EntityGraph(attributePaths = {"pet", "pet.tutor", "veterinario"})
    List<Consulta> findByPetTutorIdTutorAndStatusOrderByDataConsultaAsc(Long idTutor, StatusConsulta status);

    // Metodos de contagem e verificacao nao carregam entidades, entao nao
    // precisam de EntityGraph.

    long countByStatus(StatusConsulta status);

    boolean existsByPetIdPet(Long idPet);

    /** Guarda a regra "um pet nao pode ter duas consultas ativas no mesmo dia". */
    boolean existsByPetIdPetAndDataConsultaAndStatusIn(Long idPet,
                                                       LocalDate dataConsulta,
                                                       Collection<StatusConsulta> status);
}