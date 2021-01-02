


powders={void=0, lava=2,   fire=3,
									sand=4, acid=5,   steam=7,
									oil=9,  water=10, stone=13,
									wall=15
								}

corrosible={[2]=true,[4]=true,[9]=true,[10]=true,[13]=true}
sinkable={[2]=true,[5]=true,[9]=true,[10]=true}




function flow(x,y,pow)
	if pix(x,y+1)==0 then
		pix(x,y+1,pow)
		pix(x,y,0)
		
		local d=math.random(0,1)==0 and -1 or 1
		
		if pix(x+d,y+1)== 0 then
			pix(x+d,y+1,pow)
			pix(x,y+1,0)
		end
	else
		if math.random(0,1)==0 then
			if pix(x+1,y)==0 then
				pix(x+1,y,pow)
				pix(x,y,0)
			end
		else
			if pix(x-1,y)==0 then
				pix(x-1,y,pow)
				pix(x,y,0)
			end
		end
	end
end

function sink(x,y,pow)
	local is_sinkable = function(_x,_y)
		return sinkable[pix(_x,_y)]
	end

	local _pow=pix(x,y+1)

	if sinkable[_pow] then
		pix(x,y+1,pow)
		pix(x,y,_pow)
	else
		if is_sinkable(x+1,y+1) and is_sinkable(x+1,y) then
			pix(x,y,pix(x+1,y+1))
			pix(x+1,y+1,pow)
		elseif is_sinkable(x-1,y+1) and is_sinkable(x-1,y+1) then
			pix(x,y,pix(x-1,y+1))
			pix(x-1,y+1,pow)
		end
	end
end

function run()
	for y=sandbox.y2+5,sandbox.y,-1 do
		for x=sandbox.x,sandbox.x2+5 do
			pow=pix(x,y)
			
			--__________OIL____________
			if pow==powders['oil'] then
				flow(x,y,pow)

				burnt=false
				local rate=100

				burnt=(pix(x,y+1)==powders['lava'] or pix(x,y+1)==powders['fire']) or
										(pix(x,y-1)==powders['lava'] or pix(x,y-1)==powders['fire']) or
										(pix(x+1,y)==powders['lava'] or pix(x+1,y)==powders['fire']) or
										(pix(x-1,y)==powders['lava'] or pix(x-1,y)==powders['fire'])
				
				if burnt then
					new_draw(x,y,0)
					pix(x,y,powders['fire'])
					if pix(x,y+1)==0 then
						new_draw(x,y+1,powders['fire'])
					elseif pix(x,y+1)==pow then
						pix(x,y+1,0)
						new_draw(x,y+1,powders['fire'])
					end
					if pix(x,y-1)==0 then
						new_draw(x,y-1,powders['fire'])
					elseif pix(x,y-1)==pow then
						pix(x,y-1,0)
						new_draw(x,y-1,powders['fire'])
					end
					if pix(x+1,y)==0 then
						pix(x+1,y,powders['fire'])
					elseif pix(x+1,y)==pow then
						pix(x+1,y,0)
						new_draw(x+1,y,powders['fire'])
					end
					if pix(x-1,y)==0 then
						pix(x-1,y,powders['fire'])
					elseif pix(x-1,y)==pow then
						pix(x-1,y,0)
						new_draw(x-1,y,powders['fire'])
					end
				end
			end
			--___________________________

			
			--__________STONE____________
			if pow==powders['stone'] then
				sink(x,y,pow)
				fall(x,y,pow)
				
				if pix(x,y-1)==powders['lava'] or
							pix(x,y+1)==powders['lava'] or
							pix(x-1,y)==powders['lava'] or
							pix(x+1,y)==powders['lava'] then
					if math.random(0,100)==0 then
						pix(x,y,powders['lava'])
					end
				end
			end
			--__________________________
			
		
			
			--__________WATER____________
			if pow==powders['water'] then
				flow(x,y,pow)

				evaporated=false
				local rate=100

				if pix(x,y+1)==powders['lava'] or pix(x,y+1)==powders['fire'] and not evaporated then
					if math.random(0,100)<rate then
						pix(x,y,powders['steam'])
						evaporated=true
					end
					if pix(x,y+1)==powders['lava'] then
						pix(x,y+1,powders['stone'])
					else
						pix(x,y+1,powders['fire'])
					end
				end
				if pix(x-1,y)==powders['lava'] or pix(x-1,y)==powders['fire'] and not evaporated then
					if math.random(0,100)<rate then
						pix(x,y,powders['steam'])
						evaporated=true
					end
					if pix(x-1,y)==powders['lava'] then
						pix(x-1,y,powders['stone'])
					else
						pix(x-1,y,powders['fire'])
					end
				end
				if pix(x+1,y)==powders['lava'] or pix(x+1,y)==powders['fire'] and not evaporated then
					if math.random(0,100)<rate then
						pix(x,y,powders['steam'])
						evaporated=true
					end
					if pix(x+1,y)==powders['lava'] then
						pix(x+1,y,powders['stone'])
					else
						pix(x+1,y,powders['fire'])
					end
				end
				if pix(x,y-1)==powders['lava'] or pix(x,y-1)==powders['fire'] and not evaporated then
					if math.random(0,100)<rate then
						pix(x,y,powders['steam'])
						evaporated=true
					end
					if pix(x,y-1)==powders['lava'] then
						pix(x,y-1,powders['stone'])
					else
						pix(x,y-1,powders['fire'])
					end
				end

				if pix(x,y)==pow and pix(x,y-1)==0 then
					new_fx(x,y,8)
				end
			end
			--__________________________
			
			
			--__________LAVA____________
			if pow==powders['lava'] then
				flow(x,y,pow)

				if math.random(0,100)<10 then
				 local c=math.random(0,1)==0
					c=c and 1 or 3
					new_fx(x,y,c)
				end
			end
			--___________________________
			
			
			--__________STEAM____________
			if pow==powders['steam'] then
				local dir=math.random(-1,1)
				local rate=25

				if pix(x+dir,y-1)==0 then
					new_draw(x+dir,y-1,pow)
					pix(x,y,0)
				elseif pix(x,y-1)==powders['water'] then
					pix(x,y,powders['water'])
					pix(x,y-1,pow)
				elseif pix(x,y-1)~=0 and pix(x,y-1)~=powders['steam'] then
					if math.random(0,100)<rate then
						pix(x,y,powders['water'])
					else
						pix(x,y,0)
					end
				end

				if math.random(0,100)<50 and pix(x,y)==0 then
					new_fx(x,y,15)
				end
			end
			--__________________________
			
			
			--___________FIRE___________
			if pow==powders['fire'] then
				local dir=math.random(-1,1)
				local rate=95

				if math.random(0,100)<rate then
					if pix(x+dir,y-1)==0 then
						new_draw(x+dir,y-1,pow)
						pix(x,y,0)
					else
						if pix(x,y-1)==0 then
							new_draw(x,y-1,pow)
							pix(x,y,0)
						else
							if math.random(0,1)==0 then
								if pix(x+1,y)==0 then
									pix(x+1,y,pow)
									pix(x,y,0)
								end
							else
								if pix(x-1,y)==0 then
									pix(x-1,y,pow)
									pix(x,y,0)
								end
							end
						end
					end
				else
					pix(x,y,0)
				end

				if math.random(0,100)<50 and pix(x,y)==0 then
					local c=math.random(0,1)==0
					c=c and 1 or 4 
					new_fx(x,y,c)
				end
			end
			--__________________________
			
			
			--___________ACID___________
			if pow==powders['acid'] then
				flow(x,y,pow)
				
				if math.random(0,100)==0 then
					new_fx(x,y,6)
				end
				
				if math.random(0,100)<30 then
				if corrosible[pix(x,y+1)] then
					pix(x,y+1,0)
					pix(x,y,0)
				end
				if corrosible[pix(x-1,y)] then
					pix(x-1,y,0)
					pix(x,y,0)
				end
				if corrosible[pix(x+1,y)] then
					pix(x+1,y,0)
					pix(x,y,0)
				end
				if corrosible[pix(x,y-1)] then
					pix(x,y-1,0)
					pix(x,y,0)
				end
				end
				
				if math.random(0,100)==0 and pix(x,y)==pow then
					new_fx(x,y,6)
				end
			end
			--__________________________
			
		end
	end
	
	for _,tod in ipairs(to_draw) do
		if pix(tod.x,tod.y)==0 then
			pix(tod.x,tod.y,tod.p)
		end
	end
	
	to_draw={}
end