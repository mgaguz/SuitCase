# encoding: UTF-8
# Crawler
# civil.poderjudicial.com
# corte.poderjudicial.com
# suprema.poderjudicial.com
# laboral.poderjudicial.com

require 'nokogiri'
require 'rest-client'
require_relative 'civil.rb'
require_relative 'corte.rb'
require_relative 'suprema.rb'

class Busqueda 

	
	def AgregarCasos(listaCasos)
		puts 'listaCasos: ' + listaCasos.class.to_s
		 listaCasos.each do |caso|
		    	#puts caso.rol
		    	puts 'Caso:' + caso.class.to_s
		    	
		    	if caso.litigantes.count > 0 
			    	caso.litigantes.each do |litigantes|
			    		puts "\t" + litigantes.nombre
			    	end
				end
				

		    	if caso.rol != nil	
		    		puts 'responde a rol'
			    	if Case.exists?(:rol => caso.rol) 
			    		puts 'Caso ya Existe'
			    	else 
			    		puts 'Guardando Caso'
			    		caso.save
			    	end
			    elsif Case.exists?(:caratula => caso.caratula, :fecha => caso.fecha)	
			    		puts 'no responde a rol y si a caratula y ya existe'
			    else		    	
			    	puts 'Guardando Caso por caratula'
			    	caso.save
			    end
		    end
	end

	def BusquedaLista(lista, pagina)
		lista.each do |user|

			#Por RUT
			puts pagina.class.name.to_s
			if pagina.class.name.to_s == 'Civil'
				puts 'true'
				if user.respond_to?('rut') and user.rut != nil
					rut = user.rut.split('-')
					puts rut[0] + rut[1]
					listaCasos = pagina.Search(rut[0],rut[1],'','','')
					AgregarCasos(listaCasos)
				end
			end
			

			##Por Nombre + Apellido_Paterno
			puts 'Buscando por nombre y Apellido_Paterno'
			listaCasos = pagina.Search('','',user.name, user.first_lastname, '')
			AgregarCasos(listaCasos)

			##Por Nombres Posibles
			listaNombres = user.possible_names
			listaNombres.each do |nombre|
				listaCasos = pagina.Search('','',nombre, user.first_lastname, '')
			end
			
		end
	end
end

CRAWLER_PATH = File.dirname(__FILE__) + '/../../../crawler/' if not defined? CRAWLER_PATH
CRAWLER_PID_FILE = 'crawler.pid' if not defined? CRAWLER_PID_FILE

buscar = Busqueda.new

listaClientes = Client.all
listaUsuarios = User.all
civil = Civil.new
corte = Corte.new
suprema = Suprema.new

puts "[+] Crawler iniciado PID #{Process.pid}"
# Creamos archivo de pid
f = File.new( CRAWLER_PATH + CRAWLER_PID_FILE , "w")
f.puts(Process.pid)
f.close
while true
    # Terminamos ejecucion si se elimina archivo
    if not File.exist?( CRAWLER_PATH + CRAWLER_PID_FILE )
      puts "[+] Cerrando crawler PID #{Process.pid}"
      exit
    end

	# Primero Buscamos Casos del Usuario 
	puts 'buscando en civil -> Usuarios'
	buscar.BusquedaLista(listaUsuarios, civil)
	puts 'buscando en corte -> Usuarios'
	buscar.BusquedaLista(listaUsuarios, corte)
	puts 'buscando en suprema -> Usuarios'
	buscar.BusquedaLista(listaUsuarios, suprema)

	# Segundo Buscamos Casos de Clientes
	puts 'buscando en civil -> Usuarios'
	buscar.BusquedaLista(listaClientes, civil)
	puts 'buscando en corte -> Usuarios'
	buscar.BusquedaLista(listaClientes, corte)
	puts 'buscando en suprema -> Clientes'
	buscar.BusquedaLista(listaClientes, suprema)


	puts "[+] Iteracion Terminada"

end



