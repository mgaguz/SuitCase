
require 'nokogiri'
require 'rest-client'

require_relative 'poderjudicial.rb'

class Suprema < PoderJudicial

	$host = 'http://suprema.poderjudicial.cl'

	def Search(rut,rut_dv,nombre,apellido_paterno,apellido_materno)
		begin

			Get($host + '/SITSUPPORWEB/','Primera')

			Post($host + '/SITSUPPORWEB/InicioAplicacion.do','http://suprema.poderjudicial.cl/SITSUPPORWEB/', 'Segunda',
				{ "username" => "autoconsulta",
				  "password" => "amisoft",
				  "Aceptar" => "Ingresar"
					})

			#Get($host + '/SITSUPPORWEB/jsp/Menu/Comun/SUP_MNU_BlancoAutoconsulta.jsp', 'Tercera')

			Get($host + '/SITSUPPORWEB/AtPublicoViewAccion.do?tipoMenuATP=1','Cuarta')

			#Consulta a AtPublicoDAction.do			
			puts '[+] Ejecutando consulta '+ nombre + ' ' + apellido_paterno + ' ' + apellido_materno
			respuesta = Post($host + '/SITSUPPORWEB/AtPublicoDAction.do',
				$host + '/SITSUPPORWEB/AtPublicoViewAccion.do?tipoMenuATP=1','Quinta',
				{"TIP_Consulta" => 3,
				 "TIP_Lengueta" => "tdNombre",
				 "SeleccionL" => 0,
				 "COD_Libro" => 0,
				 "COD_Corte" => 1,
				 "COD_Corte_AP" => 0,
				 "ROL_Recurso" => "",
				 "ERA_Recurso" => "",
				 "FEC_Desde" => Time.now.strftime("%d/%m/%Y").to_s,
				 "FEC_Hasta" => Time.now.strftime("%d/%m/%Y").to_s,
				 "TIP_Litigante" => 999,
				 "TIP_Persona" => "N",
				 "APN_Nombre" => nombre.upcase,
				 "APE_Paterno" => apellido_paterno.upcase,
				 "APE_Materno" => apellido_materno.upcase,
				 "COD_CorteAP_Sda" => 0,
				 "COD_Libro_AP" => 0,
				 "ROL_Recurso_AP" => "",
				 "ERA_Recurso_AP" => "",
				 "selConsulta" => 0,
				 "ROL_Causa" => "",
				 "ERA_Causa" => "",
				 "RUC_Era" => "",
				 "RUC_Tribunal" => "",
				 "RUC_Numero" => rut.to_s,
				 "RUC_Dv" => rut_dv.to_s,
				 "COD_CorteAP_Pra" => 0,
				 "GLS_Caratulado_Recurso" => "",
				 "irAccionAtPublico" =>"Consulta"})

			getCase(respuesta)

		rescue Exception => e 
			puts "[!] Error al intentar hacer consulta: " + e.to_s
			exit
		end
	end


	def getCase(respuesta)
		doc = Nokogiri::HTML(respuesta)
		rows = doc.xpath("//*[@id='contentCells']/tbody/tr")	
		listaCasos = []

		rows[0..20].each_with_index do |row,case_number|
			caso = Case.new
			info_caso = InfoSuprema.new(case_id: caso.id)

			palabra = "\n " + case_number.to_s + ") "			
			row.xpath("td").each_with_index do |td,i|
				
				if i == 0
					info_caso.numero_ingreso = td.content.strip
				elsif i == 1
					info_caso.tipo_recurso = td.content.strip
				elsif i == 2
					caso.fecha = td.content.strip
					puts 'fecha: ' + caso.fecha.to_s
				elsif i == 3
					info_caso.ubicacion = td.content.strip
				elsif i == 4
					info_caso.fecha_ubicacion = td.content.strip
				elsif i == 5
					info_caso.corte = td.content.strip
				elsif i == 6
					caso.caratula = td.content.strip
				else
					palabra += "?: "
				end
			end

			href = row.xpath("td/a").attr('href')
			listaLitigantes = getLitigantes(href,case_number)
			
			listaLitigantes.each do |litigante|
				l = caso.litigantes.build
				l.rut = litigante.rut
				l.persona = litigante.persona
				l.nombre = litigante.nombre
				l.participante = litigante.participante
			end

			listaCasos << caso

		end

		return listaCasos

	end

	def getLitigantes(href,case_number)
		doc = Nokogiri::HTML(Get($host + href.to_s,'Consultando Litigantes Caso N° ' + case_number.to_s))
		rows = doc.xpath("//*[@id='contentCellsLitigantes']/tbody/tr")
		listaLitigantes = []
		#Litigantes
		puts "Litigantes: "			
		rows.each_with_index do |row,i|
			litigante = Litigante.new
			row.xpath("td").each_with_index do |td,j| 
				if j == 0
					litigante.participante = td.content.strip
				elsif j == 1
					litigante.rut = td.content.strip
				elsif j == 2
					litigante.persona = td.content.strip
				elsif j ==3
					litigante.nombre = td.content.strip
				else
					puts "\t ?: " + td.content.strip
				end
			end
			listaLitigantes << litigante
		end

		#getRetiros(doc) 	
		return listaLitigantes
	end

end

