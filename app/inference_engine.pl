:- dynamic entidade/1, pergunta_feita/2.

% Conta Pokémons para cada característica e valor considerando a base atual
conta_caracteristica(Caracteristica, Valor, Contagem) :-
    findall(Pokemon, (
        entidade(Pokemon),
        call(Caracteristica, Pokemon, Valor)
    ), Lista),
    length(Lista, Contagem).

% Calcula impacto da pergunta
impacto_pergunta(Caracteristica, Valor, Impacto) :-
    % Conta Pokémon que possuem a característica
    conta_caracteristica(Caracteristica, Valor, Sim),
    % Conta Pokémon que não possuem a característica
    findall(Pokemon, (
        entidade(Pokemon),
        \+ call(Caracteristica, Pokemon, Valor)
    ), ListaNao),
    length(ListaNao, Nao),
    % Impacto é a menor das duas quantidades
    Impacto is min(Sim, Nao).

% Pergunta com base nas entidades restantes
perguntar :-
    findall(Pokemon, entidade(Pokemon), ListaEntidades),
    length(ListaEntidades, NumEntidades),
    (NumEntidades = 0 ->
        writeln('Nenhuma entidade corresponde aos critérios.');
    NumEntidades = 1 ->
        format('A entidade é: ~w~n', ListaEntidades);
    % Caso ainda haja mais de uma entidade
    caracteristicas(Caracteristicas),
    findall(
        (Impacto, Caracteristica, Valor),
        (
            member(Caracteristica, Caracteristicas),
            call(Caracteristica, _, Valor),  % Obtém valores para a característica
            \+ pergunta_feita(Caracteristica, Valor), % Ignora perguntas já feitas
            conta_caracteristica(Caracteristica, Valor, Contagem),
            Contagem > 0, % Garante que haja entidades para este valor
            impacto_pergunta(Caracteristica, Valor, Impacto)
        ),
        OpcoesNaoUnicas
    ),
    (OpcoesNaoUnicas = [] ->
        writeln('Todas as perguntas já foram feitas ou não há critérios válidos restantes.');
    sort(OpcoesNaoUnicas, [(MelhorImpacto, Carac, Valor)|_]), % Seleciona a pergunta com maior impacto
    format('A entidade possui ~w igual a ~w? (s/n): ', [Carac, Valor]),
    read(Resposta),
    assert(pergunta_feita(Carac, Valor)), % Marca a pergunta como feita
    processar_resposta(Resposta, Carac, Valor, MelhorImpacto),
    perguntar)).

% Processa resposta e atualiza a base
processar_resposta(Resposta, Caracteristica, Valor, _) :-
    (Resposta == s ->
        % Mantém apenas os Pokémon que atendem à característica
        findall(Pokemon, (
            entidade(Pokemon),
            call(Caracteristica, Pokemon, Valor)
        ), Lista),
        atualizar_base(Lista)
    ;
        % Remove os Pokémon que possuem a característica
        findall(Pokemon, (
            entidade(Pokemon),
            call(Caracteristica, Pokemon, Valor)
        ), Lista),
        remover_da_base(Lista)
    ).

% Atualiza a base de conhecimento para focar nos Pokémon restantes
atualizar_base(Lista) :-
    forall(entidade(Pokemon), (
        \+ member(Pokemon, Lista) -> retract(entidade(Pokemon)) ; true
    )).

% Remove Pokémon da base
remover_da_base(Lista) :-
    forall(member(Pokemon, Lista), retract(entidade(Pokemon))).

% Lista de características disponíveis
caracteristicas([tipo, altura, peso, formato, habitat, cor]).