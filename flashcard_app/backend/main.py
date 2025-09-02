from datetime import date, timedelta
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from sqlmodel import Field, Relationship, Session, SQLModel, create_engine, select

import security

# --- Database Models ---

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(index=True, unique=True)
    hashed_password: str
    decks: List["Deck"] = Relationship(back_populates="owner")

class Deck(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    owner_id: Optional[int] = Field(default=None, foreign_key="user.id")
    owner: Optional[User] = Relationship(back_populates="decks")
    cards: List["Card"] = Relationship(back_populates="deck")

class Card(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    front: str
    back: str
    mastery_level: int = Field(default=0)
    deck_id: Optional[int] = Field(default=None, foreign_key="deck.id")
    deck: Optional[Deck] = Relationship(back_populates="cards")

class StudyLog(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    date: date
    card_id: Optional[int] = Field(default=None, foreign_key="card.id")
    deck_id: Optional[int] = Field(default=None, foreign_key="deck.id")

# --- API Models (DTOs) ---

class UserCreate(SQLModel):
    username: str
    password: str

class UserRead(SQLModel):
    id: int
    username: str

class CardRead(SQLModel):
    id: int
    front: str
    back: str
    mastery_level: int
    deck_id: int

class DeckRead(SQLModel):
    id: int
    name: str

class DeckReadWithCards(DeckRead):
    cards: List[CardRead] = []

class CardCreate(SQLModel):
    front: str
    back: str
    deck_id: int

class DeckCreate(SQLModel):
    name: str

class CardUpdate(SQLModel):
    mastery_level: Optional[int] = None

class Token(SQLModel):
    access_token: str
    token_type: str

class TokenData(SQLModel):
    username: Optional[str] = None

# --- Database Setup ---

sqlite_file_name = "database.db"
sqlite_url = f"sqlite:///{sqlite_file_name}"
engine = create_engine(sqlite_url, echo=False) # Set echo=False for cleaner logs

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session

# --- Authentication Dependencies ---

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

def get_user(session: Session, username: str):
    user = session.exec(select(User).where(User.username == username)).first()
    return user

async def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, security.SECRET_KEY, algorithms=[security.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
    user = get_user(session, username=token_data.username)
    if user is None:
        raise credentials_exception
    return user

# --- FastAPI App Setup ---

from fastapi.middleware.cors import CORSMiddleware

@asynccontextmanager
async def lifespan(app: FastAPI):
    create_db_and_tables()
    yield

app = FastAPI(lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"], 
)

# --- API Endpoints ---

@app.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends(), session: Session = Depends(get_session)):
    user = get_user(session, form_data.username)
    if not user or not security.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=security.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@app.post("/users/", response_model=UserRead)
def create_user(user: UserCreate, session: Session = Depends(get_session)):
    db_user = get_user(session, user.username)
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = security.get_password_hash(user.password)
    db_user = User(username=user.username, hashed_password=hashed_password)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

@app.get("/users/me", response_model=UserRead)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user

@app.post("/decks", response_model=DeckRead)
def create_deck(deck: DeckCreate, session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    db_deck = Deck.from_orm(deck, update={"owner_id": current_user.id})
    session.add(db_deck)
    session.commit()
    session.refresh(db_deck)
    return db_deck

@app.get("/decks", response_model=List[DeckReadWithCards])
def read_decks(session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    decks = session.exec(select(Deck).where(Deck.owner_id == current_user.id)).all()
    return decks

@app.post("/cards", response_model=CardRead)
def create_card(card: CardCreate, session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    deck = session.get(Deck, card.deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    if deck.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to add card to this deck")
    db_card = Card.from_orm(card)
    session.add(db_card)
    session.commit()
    session.refresh(db_card)
    return db_card

@app.patch("/cards/{card_id}", response_model=CardRead)
def update_card(card_id: int, card: CardUpdate, session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    db_card = session.get(Card, card_id)
    if not db_card:
        raise HTTPException(status_code=404, detail="Card not found")
    if db_card.deck.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to update this card")
    if card.mastery_level is not None:
        db_card.mastery_level = card.mastery_level
    session.add(db_card)
    session.commit()
    session.refresh(db_card)
    return db_card

@app.delete("/decks/{deck_id}")
def delete_deck(deck_id: int, session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    deck = session.get(Deck, deck_id)
    if not deck:
        raise HTTPException(status_code=404, detail="Deck not found")
    if deck.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this deck")
    for card in deck.cards:
        session.delete(card)
    session.delete(deck)
    session.commit()
    return {"ok": True}

@app.delete("/cards/{card_id}")
def delete_card(card_id: int, session: Session = Depends(get_session), current_user: User = Depends(get_current_user)):
    card = session.get(Card, card_id)
    if not card:
        raise HTTPException(status_code=404, detail="Card not found")
    if card.deck.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this card")
    session.delete(card)
    session.commit()
    return {"ok": True}

# --- Study Log Endpoints (Not Protected for now) ---

class StudyLogCreate(SQLModel):
    date: date
    card_id: Optional[int] = None
    deck_id: Optional[int] = None

class StudyLogRead(SQLModel):
    id: int
    date: date
    card_id: Optional[int] = None
    deck_id: Optional[int] = None

@app.post("/study_logs", response_model=StudyLogRead)
def create_study_log(study_log: StudyLogCreate, session: Session = Depends(get_session)):
    db_study_log = StudyLog.from_orm(study_log)
    session.add(db_study_log)
    session.commit()
    session.refresh(db_study_log)
    return db_study_log

@app.get("/study_logs", response_model=List[StudyLogRead])
def read_study_logs(session: Session = Depends(get_session)):
    study_logs = session.exec(select(StudyLog)).all()
    return study_logs

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8000)
