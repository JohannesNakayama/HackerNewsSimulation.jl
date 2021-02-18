using Distributions

# params (computed from empirical data)
LAMBDA = 0.6882627
ALPHA = 1.3441739239406807
SIGMA = 0.4203008


mutable struct Model
    post_list
    top_list
    tick
    n_users
end


mutable struct Post 
    id::Int64
    quality::Float64
    votes::Int64
    views::Int64
    timestamp::Int64
    score::Float64
end




function generate_attention(n) 
    pois = Poisson(5)
    return rand(pois, n)
end

# Wie legen wir n fest?
# Aus den Daten holen (wie viele Votes werde pro Minute abgegeben?)


# refactor
function user_interaction!(post_list, attention_list) 
    for att in attention_list
        for i in 1:att
            post_list[i].views += 1
            if post_list[i].quality > 0.5
                post_list[i].votes += 1
            end
        end
    end
    return post_list
end


function score_single(post, tick)
    age = (tick - post.timestamp) / 60
    votes = post.votes
    return ((votes - 1)^0.8)/((age + 2)^1.8)
end

function hnscore!(post_list, tick) 
    for p in post_list
        p.score = score_single(p, tick)
    end
    return post_list
end


function sort_toplist(post_list)
    toplist = sort(post_list, rev=true, by=(post -> post.score))
    return toplist
end


function bias_lambda(slice, alpha=ALPHA, sd=SIGMA)
    sd * (- alpha * sin(2 * pi  * slice))
end

function draw_arrival_rate(tick, ticks_per_day, arrival_rate_mean=LAMBDA; alpha=ALPHA, arrival_rate_sd=SIGMA)
    rel_slice = mod(tick, ticks_per_day)
    lambda = arrival_rate_mean + bias_lambda(rel_slice, alpha, arrival_rate_sd)
    dist = Poisson(lambda)
    return rand(dist)
end


function tick()

    

end


l = [draw_arrival_rate(100, 1440) for i in 1:100]

histogram(l)

using Plots

post_list = [Post(rand(Uniform(0, 1)), 1, 0, 6, 0) for i in 1:100]
attention_list = generate_attention(100)
user_interaction!(post_list, attention_list)
hnscore!(post_list, 8)
toplist = sort_toplist(post_list)

post_list



# votes + age -> wie verhalten sie sich in Bezug auf score?

