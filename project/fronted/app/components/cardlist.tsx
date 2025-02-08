"use client";
import React, { useState ,useCallback, useEffect} from "react";
import { base_prompt_en,  } from '../utils/fateprompt';
import Image from "next/image";
import { Button } from "@headlessui/react";
import MyDialog from "./ui/dialog";
import { useCurrentAccount, useSignAndExecuteTransaction } from "@mysten/dapp-kit";
import { useNetworkVariable } from "@/config/networkConfig";
import { CategorizedObjects } from "@/utils/assetsHelpers";
import { TAROT_CARDS } from "@/config/constants";
import BuyItems from "@/components/buyItems";

const AGENT_ID = process.env.NEXT_PUBLIC_ELIZA_AGENT_ID || '';
const ELIZA_URL = process.env.NEXT_PUBLIC_ELIZA_URL || '';
  

interface CardListProps {
    totalCards?: number;  // 总卡牌数量
    drawCount?: number;   // 可抽取的卡牌数量
    onSuccess?: () => void;
}

export default function CardList({ totalCards = 22, drawCount = 1,onSuccess }: CardListProps){
    const arr = Array.from({ length: totalCards }, (_, index) => index + 1);
    const [selectedCards, setSelectedCards] = useState<number[]>([]);
    const [randomNumbers, setRandomNumbers] = useState<number[]>([]);
    const [question, setQuestion] = useState('');
    const [response, setResponse] = useState('');
    const [cardValue, setCardValue] = useState<string[]>([]);

    // const handleCardClick = () => {
    //     if (selectedCards.length === drawCount && randomNumbers.length === 0) {
    //         const numbers: number[] = [];
    //         for (let i = 0; i < drawCount; i++) {
    //             const random = Math.floor(Math.random() * totalCards);
    //             numbers.push(random);
    //         }
    //         setRandomNumbers(numbers);
    //         console.log(numbers);
    //     } else if (randomNumbers.length > 0) {
    //         alert('You have already completed divination');
    //     } else {
    //         alert(`Please select ${drawCount} cards first`);
    //     }
    // };

    useEffect(() => {
        if (randomNumbers.length > 0) {
            const selectedValues = randomNumbers.map(index => TAROT_CARDS[index]?.value || '');
            setCardValue(selectedValues);
        }
    }, [randomNumbers]); 

    // const handleCardClick = () => {
    //     if (selectedCards.length === drawCount && randomNumbers.length === 0) {
    //         const numbers: number[] = [];
    //         const availableCards = arr.filter((_, index) => !selectedCards.includes(index)); // 排除已选中的卡牌
    
    //         if (availableCards.length < drawCount) {
    //             alert("Not enough unique cards available to draw.");
    //             return;
    //         }
    
    //         // 随机选择不重复的卡牌
    //         for (let i = 0; i < drawCount; i++) {
    //             const randomIndex = Math.floor(Math.random() * availableCards.length);
    //             const randomCard = availableCards[randomIndex];
    //             numbers.push(randomCard);
    //             availableCards.splice(randomIndex, 1); // 移除已选中的卡牌，避免重复
    //         }
    
    //         setRandomNumbers(numbers);

    //         console.log(numbers);  
             
    //         let cardValue = [];
    //         for (let i = 0; i < numbers.length; i++) {
    //             const index = numbers[i];
    //             if (TAROT_CARDS[index]) {
    //               const value = TAROT_CARDS[index].value;
    //               cardValue.push(value);
    //               setCardValue((prev) => [...prev, value]);

    //             }
                
    //         }
    //         console.log("setingcardValue:",cardValue); //use code for divination
    //     }
    //     else if (randomNumbers.length > 0 ) {
    //         alert('You have already completed divination');
    //     } 
    //     else {
    //         alert(`Please select ${drawCount} cards first`);
    //     }
    // };

    const handleCardClick = () => {
        if (selectedCards.length !== drawCount || randomNumbers.length > 0) {
            alert(randomNumbers.length > 0 ? 'You have already completed divination' : `Please select ${drawCount} cards first`);
            return;
        }

        const availableCards = arr.filter(card => !selectedCards.includes(card));
        if (availableCards.length < drawCount) {
            alert("Not enough unique cards available to draw.");
            return;
        }

        const drawnNumbers = new Set<number>();
        while (drawnNumbers.size < drawCount) {
            const randomCard = availableCards[Math.floor(Math.random() * availableCards.length)];
            drawnNumbers.add(randomCard);
        }

        setRandomNumbers(Array.from(drawnNumbers));
    };
    
    // const onCardClick = (index: number) => {
    //     if (selectedCards.includes(index)) {
    //         setSelectedCards(selectedCards.filter(cardIndex => cardIndex !== index));
    //     } else if (selectedCards.length < drawCount) {
    //         setSelectedCards([...selectedCards, index]);
    //     } else {
    //         alert(`You can only select ${drawCount} cards`);
    //     }
    // };


    const onCardClick = (index: number) => {
        setSelectedCards(prev =>
            prev.includes(index) ? prev.filter(card => card !== index) : prev.length < drawCount ? [...prev, index] : prev
        );
    };


    const divinationResult = () => {
        console.log("divinationResult:start");
        return (
            <div className="flex gap-4 justify-center">
                {randomNumbers.map((number, index) => (
                    <Image 
                        key={index}
                        src={`/cards/${number}.jpg`} 
                        alt={`card-${index}`} 
                        width={400} 
                        height={400} 
                        className="w-full max-w-[300px] h-auto"
                    />
                ))}
            </div>
        );
    };

    


const [loading, setLoading] = useState(false);

const handleSubmit = useCallback(async (cardValue: string[], question: string) => {
    if (loading) return; // 避免重复提交

    setLoading(true);
    setResponse(""); // 清空上次的结果
    console.log("handleSubmit:start");
    console.log("use:", cardValue);
    console.log("question:", question);

    const formDataToSend = new FormData();
    formDataToSend.append('user', '');
    formDataToSend.append('text', base_prompt_en + "Cards:" + cardValue + "\n" + question);
    formDataToSend.append('action', "NONE");

    console.log("url:", ELIZA_URL + AGENT_ID + '/message');

    try {
        const response = await fetch(ELIZA_URL + AGENT_ID + '/message', {
            method: 'POST',
            body: formDataToSend,
            headers: {
                'Accept': 'application/json',
                'Accept-Language': 'zh-CN,zh;q=0.9',
            },
        });

        if (!response.ok) throw new Error(`HTTP error! Status: ${response.status}`);

        const data = await response.json();
        console.log("response data：", data);

        setResponse(data.map((item: any) => item.text).join("\n")); // 处理响应
    } catch (error) {
        console.error("请求失败:", error);
        setResponse(`❌ 请求失败: ${(error as Error).message}`);
    } finally {
        setLoading(false);
    }
}, [loading]); // 依赖项，避免 handleSubmit 频繁重新创建


    return (
        <div className="flex w-full h-full flex-col items-center justify-center overflow-x-auto mt-10">
            <div className="w-5/6 h-72 relative min-w-[800px] mt-10">
                {arr.map((item, index) => (
                    <div
                        key={index}
                        onClick={() => onCardClick(index)}
                        className={`ml-10
                            absolute transition-all duration-300 ease-in-out 
                            hover:-translate-y-6
                            ${selectedCards.includes(index) ? '-translate-y-6' : ''}
                        `}
                        style={{
                            left: `${index * 40}px`,
                            zIndex: arr.length - index
                        }}
                    >
                        <Image
                            src="/card.png"
                            alt="cardlist"
                            className="object-cover"
                            width={120}
                            height={200}
                        />
                    </div>
                ))}
            </div>
            <div className='w-full flex flex-col items-center gap-6 mt-20 z-10'onClick={() => handleCardClick()} >
                <p className="text-purple-600">
                    Selected: {selectedCards.length} / {drawCount} cards
                </p>
                  {/* 问题输入 */}
                  <input type="text" placeholder="Enter your question" className="w-1/4 p-2 border border-gray-300 rounded-md" onChange={(e) => setQuestion(e.target.value)}/>

                    <div className='w-1/4'>

                    <BuyItems onSuccess={()=>{
                        if (!loading) handleSubmit(cardValue, question);
                        }}/>
                    </div>
                    {loading && <p className="text-blue-500">Loading...</p>}

                  <div className="text-purple-600">{response}</div>

            </div>
        </div>
    );
    
}