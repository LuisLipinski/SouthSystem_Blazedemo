# BlazeDemo Performance Test

## Link do repositorio
Substituir pelo link publico do GitHub:

`https://github.com/<seu-usuario>/blazedemo-performance-test`

## Objetivo
Automacao de teste de performance para o fluxo de compra de passagem no site:

- URL: https://www.blazedemo.com
- Ferramenta: Apache JMeter 5.6.3

## Cenario testado
Compra de passagem com sucesso:

1. Abrir home
2. Buscar voos
3. Escolher o voo
4. Finalizar compra
5. Validar mensagem: "Thank you for your purchase today!"

## Criterio de aceitacao

1. 250 requisicoes por segundo
2. Tempo de resposta percentil 90 menor que 2 segundos

## Estrategia de teste

### Teste de carga
- Arquivo: `jmeter/blazedemo_load_test.jmx`
- Grupo ativo: Load Thread Group
- Usuarios: 300
- Ramp-up: 60s
- Duracao: 180s
- Throttle (ConstantThroughputTimer): 15000 amostras/min = 250 req/s alvo

### Teste de pico
- Arquivo: `jmeter/blazedemo_spike_test.jmx`
- Grupo ativo: Spike Thread Group
- Usuarios: 500
- Ramp-up: 5s
- Duracao: 120s
- Ramp-up abrupto simula spike real de trafego

Observacao:
- Cada script limpa o `.jtl` e a pasta de dashboard anterior antes de executar.
- Isso evita mistura de resultados entre execucoes.

## Como executar

### Pre-requisitos

1. Windows
2. Java 8+ instalado e disponivel no PATH
3. JMeter 5.6.3

Os scripts tentam primeiro o caminho local:

`C:\Users\Usuario\Documents\apache-jmeter-5.6.3\bin\jmeter.bat`

Se nao encontrar, usam `jmeter` no PATH.

### Executar carga

```bat
run_load_test.bat
```

Saidas:

1. `results/load_test_results.jtl`
2. `results/load_report/index.html`

### Executar pico

```bat
run_spike_test.bat
```

Saidas:

1. `results/spike_test_results.jtl`
2. `results/spike_report/index.html`

## Relatorio de execucao

Fontes utilizadas:

1. `results/load_report/statistics.json`
2. `results/spike_report/statistics.json`

### Resultado - Load Test

- Fluxo principal: Buy Ticket Flow
- Throughput da transacao: 60.95 transacoes/s
- Requisicoes/s aproximadas no fluxo: 60.95 x 4 = 243.80 req/s
- P90 (`pct1ResTime`): 1478 ms (1.48 s)
- Erro no fluxo: 0.00%

### Resultado - Spike Test

- Fluxo principal: Buy Ticket Flow - Spike
- Throughput da transacao: 50.45 transacoes/s
- Requisicoes/s aproximadas no fluxo: 50.45 x 4 = 201.80 req/s
- P90 (`pct1ResTime`): 8149.4 ms (8.15 s)
- Erro no fluxo: 0.00%

## Conclusao do criterio de aceitacao

Nao atendido.

Motivos:

1. Vazao abaixo do esperado em ambos os testes (243.80 e 201.80 req/s vs 250 req/s).
2. P90 atende no load (1.48s), mas nao atende no spike (8.15s).
3. No spike, mesmo sem erros, a latencia sob aumento abrupto ainda ficou alta para o SLA.

## Analise de raiz

Por que o criterio nao foi atingido?

O throughput real e limitado pela combinacao entre o numero de threads e o tempo de resposta medio do servidor:

```
Throughput max = Threads / (Avg response time em segundos)
Req/s max (HTTP) = Throughput max * 4 (requisicoes por fluxo)
```

Registros do load test anterior (150 threads):

- Tempo medio do fluxo: 3.73s
- Throughput maximo possivel: 150 / 3.73 = 40.2 transacoes/s
- Req/s maximo: 40.2 * 4 = 160.8 req/s

O ConstantThroughputTimer foi configurado em 15000 amostras/min (250 req/s), mas como o pool de threads nao conseguia entregar mais que ~160 req/s, o timer nao tinha efeito pratico: as threads eram o gargalo.

Para atingir 250 req/s com fluxo de 4 requisicoes e avg de 3.73s:

```
Threads necessarias = (250 req/s / 4) * 3.73s = 233 threads
Com margem de 30%: ~300 threads
```

Por isso o load test foi ajustado para 300 threads.

Limitacao do ambiente BlazeDemo:
O blazedemo.com e um ambiente publico de demonstracao, compartilhado entre todos os usuarios. A latencia observada (P90 > 8s) nao reflete um sistema saudavel: indica que o servidor comeca a degradar sob carga. Em um sistema real com infra dedicada, os tempos seriam significativamente menores e o criterio de 250 req/s com P90 < 2s seria muito mais alcancavel.

## Propostas de melhoria

### Se o objetivo e atingir 250 req/s no BlazeDemo

1. Aumentar o numero de threads progressivamente (300, 400, 500) ate saturar a vazao alvo.
2. Monitorar se o aumento de threads gera aumento proporcional de throughput ou apenas de erros.
3. Se o servidor comecar a retornar erros 5xx, a limitacao e do backend, nao do JMeter.

### Se o objetivo e demostrar a capacidade do script

1. Usar um ambiente dedicado (ex: aplicacao local com Docker, Spring Boot, ou ambiente de staging).
2. Com servidor dedicado, a latencia esperada para fluxos simples e < 500ms, o que permite atingir facilmente 250 req/s com 150-200 threads.
3. Calcular antes quantas threads sao necessarias: `Threads = TPS_alvo * Avg_response_time`.

### Melhorias tecnicas no script JMeter

1. Remover listeners `View Results Tree` do modo batch para reduzir overhead de memoria.
2. Adicionar `DurationAssertion` por sampler para garantir SLA por requisicao, nao so pelo fluxo.
3. Adicionar `ResponseCodeAssertion` para tratar redirects inesperados como falha.
4. Usar o `bzm - Concurrency Thread Group` (plugin JMeter) no lugar do ThreadGroup padrao para controle de concorrencia mais preciso e com grafico de rampa suave.
5. Parametrizar origens e destinos de voo via CSV para variar dados e evitar cache do servidor.

## Evidencias

1. Dashboard carga: `results/load_report/index.html`
2. Dashboard pico: `results/spike_report/index.html`
3. Log carga: `results/load_test_results.jtl`
4. Log pico: `results/spike_test_results.jtl`

## Consideracoes finais

1. Os avisos `StatusConsoleListener` vistos na execucao do JMeter sao warnings de plugin scan e nao impedem o teste.
2. A avaliacao principal foi feita no fluxo transacional fim-a-fim de compra, que representa melhor o cenario de negocio solicitado.

