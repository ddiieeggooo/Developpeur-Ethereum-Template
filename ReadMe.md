Testings Projet 2

TESTS

J'ai essayé d'écrire des tests pour chacune des fonctions, j'ai commencé par les getters, ensuite j'ai écrit des tests pour vérifier qu'un voter était bien enregistré et qu'il ne pouvait pas être enregistré s'il l'était déjà. J'ai continué avec les tests des proposals, pour vérifier si une proposal était bien enregistrée, et pour vérifier le revert si jamais la session des proposals n'avait pas démarrée ou était terminée. Ensuite j'ai écrit un test pour vérifier que les votes passaient bien, et qu'ils étaient bien revert si le voter ne choisissait pas un bon proposalId, ou que la session de vote n'avait pas commencé ou était terminée. Par la suite j'ai écrit un test pour vérifier que le changement de workflow s'oppérait correctement pour chaque situation de l'enum. J'ai terminé les test par la vérification qu'un gagant était correctement obtenu quand il obtenait la majorité.
