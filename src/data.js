export const habits = [
 {id:'agua',titulo:'Beber água',meta:'2,5 litros',periodicidade:'diaria',icone:'◉'},
 {id:'leitura',titulo:'Leitura',meta:'20 minutos',periodicidade:'diaria',icone:'▤'},
 {id:'exercicio',titulo:'Exercícios',meta:'5 vezes por semana',periodicidade:'semanal',icone:'↗'},
 {id:'meditacao',titulo:'Meditação',meta:'Diariamente',periodicidade:'diaria',icone:'✧'},
 {id:'agenda',titulo:'Revisar agenda',meta:'Diariamente',periodicidade:'diaria',icone:'▦'}
];
export const library = [
 {id:'habitos',titulo:'Pequenos hábitos, grandes mudanças',categoria:'Hábitos',descricao:'Construa uma rotina com pequenos passos consistentes.',url:'https://jamesclear.com/habits',icone:'✿'},
 {id:'produtividade',titulo:'Faça espaço para o que importa',categoria:'Produtividade',descricao:'Conheça o método GTD e organize suas próximas ações.',url:'https://gettingthingsdone.com/what-is-gtd/',icone:'↗'},
 {id:'organizacao',titulo:'Uma mente mais organizada',categoria:'Organização',descricao:'Ideias práticas para cuidar da sua rotina e do seu tempo.',url:'https://vidaorganizada.com/',icone:'▦'},
 {id:'foco',titulo:'Uma coisa de cada vez',categoria:'Foco',descricao:'Descubra o Pomodoro e encontre seu ritmo de concentração.',url:'https://www.pomodorotechnique.com/',icone:'◷'}
];
export function localDate(d=new Date()){return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`}
