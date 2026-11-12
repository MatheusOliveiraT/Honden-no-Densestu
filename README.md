# Honden no Desestu

RPG top-down em pixel art desenvolvido na **Godot Engine 4** (GDScript).

## Funcionalidades

- **Exploração Top-Down:** Movimentação com corrida, profundidade dinâmica (Y-Sort), colisões por camadas e câmera limitada automaticamente às bordas do mapa.
- **Sistema de Batalha & Progressão:** Combates por turnos, gerenciamento de HP/MP, inventário, equipamentos (armas e armaduras), almas e moedas.
- **Sistema de Save/Load:** 3 slots de salvamento com captura de miniatura (thumbnail) da tela e registro de data/hora.
- **Cutscenes & Diálogos:** Sistema de narração e diálogos sequenciais com efeito de digitação (*typewriter*) e suporte a ilustrações.
- **Interface Retrô & Suporte a Controle:** Menu principal, menu de pausa, inventário, popup de controles e diálogos de confirmação navegáveis por teclado, mouse e joystick.

## Controles

| Ação | Teclado | Controle (PS / Xbox / Nintendo) |
| :--- | :--- | :--- |
| **Mover** | `W A S D` / `Setas Direcionais` | `D-Pad` / `Analógico Esquerdo` |
| **Correr** | `Shift` / `Z` | `Cross (X)` / `A` / `B` |
| **Interagir / Avançar Diálogo** | `X` | `Circle (O)` / `B` / `A` |
| **Inventário** | `I` | `Triangle (△)` / `Y` / `X` |
| **Menu / Voltar / Pular Cutscene** | `ESC` | `Start` / `Menu` / `+` |

## Tecnologias Utilizadas

- **Engine:** Godot 4.x
- **Linguagem:** GDScript
- **Arte:** Pixel Art (`Nearest` texture filtering)

## Como Executar

1. Clone este repositório:
   ```bash
   git clone https://github.com/MatheusOliveiraT/Honden-no-Densestu.git
   ```
2. Abra a Godot Engine 4.
3. Clique em Importar e selecione o arquivo project.godot na pasta raiz do projeto.
4. Pressione F5 para iniciar o jogo.
