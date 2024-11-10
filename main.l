%{
/**
objetivo:
    elaborar un analizador léxico en lex/flex que reconozca los componentes léxicos pertenecientes a las
    clases abajo descritas.
autor: luis ángel quintana mora
fecha elaboración: 25-09-2024
*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    int clave;
    char *valor;
} Item;

typedef struct {
    Item *items;
    size_t size;
    size_t capacity;
} Tabla;

typedef struct {
    int clave;
    int valor;
} ItemToken;

typedef struct {
    ItemToken *items;
    size_t size;
    size_t capacity;
} TablaToken;

typedef struct {
    int posicion;
    char *nombre;
    char *tipo;
    int valor;
} Simbolo;

typedef struct {
    Simbolo *simbolos;
    size_t size;
    size_t capacity;
} TablaSimbolos;


const char* catalogo_palabras_reservadas[] = {
    "BREAK",
    "CASE",
    "CHAR",
    "CONTINUE",
    "DO",
    "DOUBLE",
    "ELSE",
    "FLOAT",
    "FOR",
    "IF",
    "INT",
    "LONG",
    "RETURN",
    "SHORT",
    "SIZEOF",
    "SWITCH",
    "UNSIGNED",
    "VOID",
    "WHILE"
};

const char* catalogo_op_aritmeticos[] = {
    "+",
    "-",
    "*",
    "/",
    "%",
    "++",
    "--",
    "**"
};

const char* catalogo_op_logicos[] = {
    "||",
    "&&",
    "!"
};

const char* catalogo_op_asignacion[] = {
    "=",
    "+=",
    "-=",
    "*=",
    "/=",
    "%=",
    "&=",
    "^=",
    "|=",
    "<<=",
    ">>="
};

FILE *yyin;
Tabla *tabla_cadenas;
Tabla *tabla_flotantes;
TablaSimbolos *tabla_simbolos;
TablaToken *tabla_tokens;

size_t sizeCatalogoPalabrasReservadas = 19;
size_t sizeCatalogoOpAritmeticos = 8;
size_t sizeCatalogoOpLogicos = 3;
size_t sizeCatalogoOpAsignacion = 11;

int indice_cadenas = 0;
int indice_flotantes = 0;
int indice_simbolos = 0;

void showError(char* e);
int yywrap();
void push(int clase, char *text);

Tabla* crearTabla();
TablaSimbolos* crearTablaSimbolos();
TablaToken* crearTablaTokens();

void agregarItem(Tabla *tabla, int clave, const char *valor);
void agregarSimbolo(TablaSimbolos *tabla, int posicion, const char *nombre, const char *tipo, int valor);
void agregarToken(TablaToken *tabla, int clave, int valor);

void mostrarTablaCadenas(const Tabla *tabla);
void mostrarTablaFlotantes(const Tabla *tabla);
void mostrarTablaSimbolos(const TablaSimbolos *tabla);
void mostrarTablaTokens(const TablaToken *tabla);

int obtenerPosicionCatalogo(const char** catalogo, char *text, int size);

int limpiarEntero(const char* entero);
char* eliminarHashExtremos(const char* cadena);
void strip(char *cadena);

%}
%option yylineno

ENTERO_NEGATIVO -[0-9]+l?
ENTERO_POSITIVO [0-9]+(u|l|ul)?
ENTERO {ENTERO_NEGATIVO}|{ENTERO_POSITIVO}
NO_ENTERO -[0-9]+(u|ul)
FLOAT_EXPONENCIALES [e][+-]?[0-9]+
FLOAT_EC ec[0-9]+
FLOTANTE [+-]?([0-9]+[.][0-9]+)({FLOAT_EXPONENCIALES}|{FLOAT_EC})?
NO_FLOAT [+-]?(([0-9]+[.])|([.][0-9]+))
SUMA "+"
RESTA "-"
MULTI "*"
DIVI "/"
RESIDUO "%"
INCREMENTO "++"
DECREMENTO "--"
POTENCIA "**"
OP_ARITMETICO {SUMA}|{RESTA}|{MULTI}|{DIVI}|{RESIDUO}|{INCREMENTO}|{DECREMENTO}|{POTENCIA}
SIMBOLO_ESPECIAL [{}[\]()\.]
CONTENIDO_CADENA [ -"$-~]{5,}
CADENA (#){CONTENIDO_CADENA}(#)
PR_BREAK "BREAK"
PR_CASE "CASE"
PR_CHAR "CHAR"
PR_CONTINUE "CONTINUE"
PR_DO "DO"
PR_DOUBLE "DOUBLE"
PR_ELSE "ELSE"
PR_FLOAT "FLOAT"
PR_FOR "FOR"
PR_IF "IF"
PR_INT "INT"
PR_LONG "LONG"
PR_RETURN "RETURN"
PR_SHORT "SHORT"
PR_SIZEOF "SIZEOF"
PR_SWITCH "SWITCH"
PR_UNSIGNED "UNSIGNED"
PR_VOID "VOID"
PR_WHILE "WHILE"
PALABRA_RESERVADA {PR_BREAK}|{PR_CASE}|{PR_CHAR}|{PR_CONTINUE}|{PR_DO}|{PR_DOUBLE}|{PR_ELSE}|{PR_FLOAT}|{PR_FOR}|{PR_IF}|{PR_INT}|{PR_LONG}|{PR_RETURN}|{PR_SHORT}|{PR_SIZEOF}|{PR_SWITCH}|{PR_UNSIGNED}|{PR_VOID}|{PR_WHILE}
IGUAL "="
OPA_ADICION "+="
OPA_SUSTRACCION "-="
OPA_MULTI "*="
OPA_DIVI "/="
OPA_RESIDIUO "%="
OPA_AND "&="
OPA_XOR "^="
OPA_OR "|="
OPA_IZQUIERDA "<<="
OPA_DERECHA ">>="
OPERADOR_ASIGNACION {IGUAL}|{OPA_ADICION}|{OPA_SUSTRACCION}|{OPA_MULTI}|{OPA_DIVI}|{OPA_RESIDIUO}|{OPA_AND}|{OPA_XOR}|{OPA_OR}|{OPA_IZQUIERDA}|{OPA_DERECHA}
OP_OR "||"
OP_AND "&&"
OP_NOT "!"
OPERADOR_LOGICO {OP_OR}|{OP_AND}|{OP_NOT}
SALTO_LINEA "\n"
TABULACION "\t"
ESPACIO " "
DELIMITADOR {SALTO_LINEA}|{TABULACION}|{ESPACIO}
IDENTIFICADOR ([a-zA-Z][a-zA-Z0-9_]{0,14}){DELIMITADOR}
NO_IDENTIFICADOR ([0-9][a-zA-Z0-9_]*)
COMENTARIO_LINEA "~~".*
COMENTARIO_BLOQUE "~/"(.|\n)*"\~"

%%
{ENTERO}                {push(0, yytext);}
{FLOTANTE}              {push(1, yytext);}
{OP_ARITMETICO}         {push(2, yytext);}
{SIMBOLO_ESPECIAL}      {push(3, yytext);}
{CADENA}                {push(4, yytext);}
{PALABRA_RESERVADA}     {push(5, yytext);}
{OPERADOR_ASIGNACION}   {push(6, yytext);}
{OPERADOR_LOGICO}       {push(7, yytext);}
{IDENTIFICADOR}         {push(8, yytext);}
{COMENTARIO_LINEA}      {}
{COMENTARIO_BLOQUE}     {}

"\n"
"\t"
" "{1,}

{NO_FLOAT} {printf("\nFlotante inválido: \n");showError(yytext);} // si existe un float con digitos faltantes
{NO_ENTERO} {printf("\nEntero inválido: \n"); showError(yytext);} 
{NO_IDENTIFICADOR} {printf("\nIdentificador inválido: \n"); showError(yytext);} 
.           {showError(yytext);} 
%%

void push(int clase, char *text){
    int valor;

    switch(clase)
    {
        // enteros
        case 0:
            valor = limpiarEntero(text);
            break;
        // flotantes
        case 1:
            agregarItem(tabla_flotantes, indice_flotantes, text);
            valor = indice_flotantes;
            indice_flotantes++;
            break;
        // op. aritmeticos
        case 2:
            // se asigna como valor la posicion en su catalogo
            valor = obtenerPosicionCatalogo(catalogo_op_aritmeticos, text, sizeCatalogoOpAritmeticos);
            break;
        // simbolo especial
        case 3:
            // castear a int para obtener ascii
            valor = (int)text[0];
            break;

        // cadenas
        case 4:
            agregarItem(tabla_cadenas, indice_cadenas, eliminarHashExtremos(text));
            valor = indice_cadenas; 
            indice_cadenas++;
            break;

        // palabra reservada
        case 5:
            valor = obtenerPosicionCatalogo(catalogo_palabras_reservadas, text, sizeCatalogoPalabrasReservadas);
            break;

        // op. asignacion
        case 6:
            valor = obtenerPosicionCatalogo(catalogo_op_asignacion, text, sizeCatalogoOpAsignacion);
            break;

        // op. logicos
        case 7:
            valor = obtenerPosicionCatalogo(catalogo_op_logicos, text, sizeCatalogoOpLogicos);
            break;

        // identificadores
        case 8:
            valor = indice_simbolos;
            strip(text);
            agregarSimbolo(tabla_simbolos, valor, text, "INT", -1);
            indice_simbolos++;
            break;

        default:
            printf("\n\tERROR: %s\n", text);
    }

    agregarToken(tabla_tokens, clase, valor);
}

int yywrap(){
    return -1;
}

void showError(char* e){
    printf("\n\t\033[31mERROR léxico, omitiendo\033[0m -> %s\n", e);
}

// función para crear la tabla 
Tabla* crearTabla() {
    Tabla *tabla = malloc(sizeof(Tabla));
    tabla->items = malloc(2 * sizeof(Item));
    tabla->size = 0;
    tabla->capacity = 2;
    return tabla;
}

// función para crear la tabla tokens
TablaToken* crearTablaTokens() {
    TablaToken *tabla = malloc(sizeof(TablaToken));
    tabla->items = malloc(2 * sizeof(ItemToken));
    tabla->size = 0;
    tabla->capacity = 2;
    return tabla;
}

// función para crear la tabla de simbolos
TablaSimbolos* crearTablaSimbolos() {
    TablaSimbolos *tabla = malloc(sizeof(TablaSimbolos));
    tabla->simbolos = malloc(2 * sizeof(Simbolo));
    tabla->size = 0;
    tabla->capacity = 2;
    return tabla;
}


// función para agregar a la tabla
void agregarItem(Tabla *tabla, int clave, const char *valor) {
    if (tabla->size == tabla->capacity) {
        tabla->capacity *= 2; // duplicar la capacidad
        tabla->items = realloc(tabla->items, tabla->capacity * sizeof(Item));
    }
    tabla->items[tabla->size].clave = clave; // asignar la clase
    tabla->items[tabla->size].valor = malloc(strlen(valor) + 1); // reservar memoria para el valor
    strcpy(tabla->items[tabla->size].valor, valor); // copiar el valor
    tabla->size++;
}

// función para agregar a la tabla de tokens
void agregarToken(TablaToken *tabla, int clave, int valor) {
    if (tabla->size == tabla->capacity) {
        tabla->capacity *= 2; // duplicar la capacidad
        tabla->items = realloc(tabla->items, tabla->capacity * sizeof(ItemToken));
    }
    tabla->items[tabla->size].clave = clave; // asignar la clase
    tabla->items[tabla->size].valor = valor; // reservar memoria para el valor
    tabla->size++;
}

// función para agregar a la tabla de simbolos
void agregarSimbolo(TablaSimbolos *tabla, int posicion, const char *nombre, const char *tipo, int valor) {
    if (tabla->size == tabla->capacity) {
        tabla->capacity *= 2; // duplicar la capacidad
        tabla->simbolos = realloc(tabla->simbolos, tabla->capacity * sizeof(Simbolo));
    }
    tabla->simbolos[tabla->size].posicion = posicion;

    tabla->simbolos[tabla->size].nombre = malloc(strlen(nombre) + 1); // reservar memoria para el valor
    strcpy(tabla->simbolos[tabla->size].nombre, nombre); // copiar el valor

    tabla->simbolos[tabla->size].tipo = malloc(strlen(tipo) + 1);
    strcpy(tabla->simbolos[tabla->size].tipo, tipo);

    tabla->simbolos[tabla->size].valor = valor;
    tabla->size++;
}

// función para mostrar el contenido de la tabla de tokens
void mostrarTablaTokens(const TablaToken *tabla) {
    printf("\nTOKENS\n");
    if (tabla->size == 0){
        printf("\n\t(vacia)\n");
    }

    for (size_t i = 0; i < tabla->size; i++) {
        printf("(%d, %d)\n", tabla->items[i].clave, tabla->items[i].valor);
    }
}

// función para mostrar el contenido de la tabla de cadenas
void mostrarTablaCadenas(const Tabla *tabla) {
    printf("\nTABLA DE CADENAS\n");
    if (tabla->size == 0){
        printf("\n\t(vacia)\n");
    }

    for (size_t i = 0; i < tabla->size; i++) {
        printf("posición: %d, dato: %s\n", tabla->items[i].clave, tabla->items[i].valor);
    }
}

// función para mostrar el contenido de la tabla de simbolos
void mostrarTablaSimbolos(const TablaSimbolos *tabla) {
    printf("\nTABLA DE SIMBOLOS\n");
    if (tabla->size == 0){
        printf("\n\t(vacia)\n");
    }

    for (size_t i = 0; i < tabla->size; i++) {
        printf("posicion: %d, nombre: %s, tipo: %s, valor: %d\n", tabla->simbolos[i].posicion, tabla->simbolos[i].nombre, tabla->simbolos[i].tipo, tabla->simbolos[i].valor);
    }
}

// función para mostrar el contenido de la tabla de flotantes
void mostrarTablaFlotantes(const Tabla *tabla) {
    printf("\nTABLA DE FLOTANTES\n");
    if (tabla->size == 0){
        printf("\n\t(vacia)\n");
    }

    for (size_t i = 0; i < tabla->size; i++) {
        printf("posición: %d, dato: %s\n", tabla->items[i].clave, tabla->items[i].valor);
    }
}


int obtenerPosicionCatalogo(const char** catalogo, char *text, int size){
    for (int i = 0; i < size; i++) {
        if (strcmp(text, catalogo[i]) == 0){
            return i;
        }
    }

    return -1;
}


int limpiarEntero(const char* entero) {
    char* result = (char*)malloc(strlen(entero) + 1);
    int final;

    int j = 0;
    int leading_zero = 1;

    for (int i = 0; entero[i] != '\0'; i++) {
        char current = entero[i];

        // verifica si el carácter es 'u', 'l' o '0'
        if (current == 'u' || current == 'l') {
            continue; // salta 'u' y 'l'
        }

        if (current == '0' && leading_zero) {
            continue; // salta los ceros a la izquierda
        } else {
            leading_zero = 0; // se encontró un número distinto de '0'
        }

        result[j++] = current; // agrega el carácter a la nueva cadena
    }

    // si la cadena resultante está vacía, devuelve "0"
    if (j == 0) {
        result[j++] = '0';
    }

    result[j] = '\0'; // termina la nueva cadena

    final = atoi(result);

    return final;
}

// función que elimina los caracteres '#' al inicio y al final de una cadena
char* eliminarHashExtremos(const char* cadena) {
    int inicio = 0;
    int fin = strlen(cadena) - 1;

    // verificar si el primer carácter es '#'
    if (cadena[inicio] == '#') {
        inicio++;
    }

    // verificar si el último carácter es '#'
    if (cadena[fin] == '#') {
        fin--;
    }

    // calcular la longitud de la nueva cadena sin los '#' de los extremos
    int longitud = fin - inicio + 1;
    if (longitud <= 0) {
        return strdup("");
    }

    // asignar memoria para la nueva cadena con la longitud calculada más uno para el terminador nulo
    char* nuevaCadena = (char*)malloc((longitud + 1) * sizeof(char));
    if (nuevaCadena == NULL) {
        // retornar NULL si falla la asignación de memoria
        return NULL;
    }

    // copiar la subcadena sin los '#' de los extremos a la nueva cadena
    strncpy(nuevaCadena, cadena + inicio, longitud);
    nuevaCadena[longitud] = '\0';

    return nuevaCadena;
}

void strip(char *cadena) {
    int i = 0, j = 0;
    while (cadena[i] != '\0') {
        // Si el carácter no es espacio, salto de línea ni tabulación, lo copio
        if (cadena[i] != ' ' && cadena[i] != '\n' && cadena[i] != '\t') {
            cadena[j++] = cadena[i];
        }
        i++;
    }
    // Terminar la cadena con el carácter nulo
    cadena[j] = '\0';
}


int main(int argc, char *argv[]){
    // leer archivo de entrada
    yyin = fopen(argv[1], "rt");

    tabla_tokens = crearTablaTokens();
    tabla_cadenas = crearTabla();
    tabla_flotantes = crearTabla();
    tabla_simbolos = crearTablaSimbolos();

    if (yyin == NULL){
        printf("\nel archivo no se puede abrir: %s\n", argv[1]);
        return 1;
    }

    yylex();

    mostrarTablaCadenas(tabla_cadenas);
    mostrarTablaFlotantes(tabla_flotantes);
    mostrarTablaSimbolos(tabla_simbolos);
    mostrarTablaTokens(tabla_tokens);

    fclose(yyin);
    return 0;
}