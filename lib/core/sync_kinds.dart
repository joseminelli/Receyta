/// Os tipos de item que a sincronização conhece (a coluna `kind` de
/// `sync_docs` e de `sync_tombstones`). Uma constante só pra os DAOs e o motor
/// falarem do mesmo jeito.
const kSyncKindRecipe = 'recipe';
const kSyncKindFolder = 'folder';
const kSyncKindMealPlan = 'meal_plan';
const kSyncKindShoppingList = 'shopping_list';
const kSyncKindShoppingItem = 'shopping_item';
const kSyncKindCookLog = 'cook_log';
const kSyncKindPantry = 'pantry';
